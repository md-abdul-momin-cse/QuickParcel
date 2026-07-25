import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/coustomer/find_driver.dart';
import 'package:quick_parcel/coustomer/signUp.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/google_places_service.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/models/order_model.dart';
import 'package:quick_parcel/services/pending_order_service.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendPackage extends StatefulWidget {
  const SendPackage({super.key});

  @override
  State<SendPackage> createState() => _SendPackageState();
}

class _SendPackageState extends State<SendPackage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              SendPackageWidgets.buildSectionHeader(
                title: 'Manage Parcels',
                icon: Icons.local_shipping,
              ),

              // Search Bar
              SendPackageWidgets.buildSearchBar(
                onTap: () => _showLocationPicker(context),
              ),

              const SizedBox(height: 30),

              // types of deliveries
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Types of deliveries',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Send / Receive Items Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SendPackageWidgets.buildDeliveryTypeCard(
                        imagePath: 'images/send_package.png',
                        title: 'Send items',
                        onTap: () =>
                            _showLocationPicker(context, isSending: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SendPackageWidgets.buildDeliveryTypeCard(
                        imagePath: 'images/my_package.png',
                        title: 'Receive items',
                        onTap: () =>
                            _showLocationPicker(context, isSending: false),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Popular ways to use Parcel - Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular ways to use Parcel',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore some of the many items you can send or receive with Parcel.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save yourself a trip across town
                    SendPackageWidgets.buildPopularWaysSection(
                      title: 'Save yourself a trip across town',
                      items: [
                        {
                          'icon': Icons.diamond_outlined,
                          'label': 'Forgotten items',
                        },
                        {'icon': Icons.card_giftcard, 'label': 'Gifts'},
                        {
                          'icon': Icons.inventory_2_outlined,
                          'label': 'Packages',
                        },
                        {
                          'icon': Icons.dry_cleaning_outlined,
                          'label': 'Dry cleaning',
                        },
                        {
                          'icon': Icons.storefront_outlined,
                          'label': 'Marketplace items',
                        },
                        {
                          'icon': Icons.volunteer_activism_outlined,
                          'label': 'Donations',
                        },
                        {
                          'icon': Icons.local_florist_outlined,
                          'label': 'Flowers',
                        },
                        {
                          'icon': Icons.cake_outlined,
                          'label': 'Homemade gifts',
                        },
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Deliver items for your business
                    SendPackageWidgets.buildPopularWaysSection(
                      title: 'Deliver items for your business',
                      items: [
                        {
                          'icon': Icons.description_outlined,
                          'label': 'Documents',
                        },
                        {'icon': Icons.key_outlined, 'label': 'Keys'},
                        {
                          'icon': Icons.shopping_bag_outlined,
                          'label': 'Products',
                        },
                        {
                          'icon': Icons.receipt_long_outlined,
                          'label': 'Supplies',
                        },
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, {bool isSending = true}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(isSending: isSending),
      ),
    );
  }
}

// Location Picker Screen - Professional with Google Places
class LocationPickerScreen extends StatefulWidget {
  final bool isSending;

  const LocationPickerScreen({super.key, this.isSending = true});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final GooglePlacesService _placesService = GooglePlacesService();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropoffController = TextEditingController();
  final FocusNode pickupFocusNode = FocusNode();
  final FocusNode dropoffFocusNode = FocusNode();

  // Session token for Google Places API billing optimization
  String _sessionToken = const Uuid().v4();

  // State variables
  String? selectedPickupTime = 'Pick up now';
  bool _isSearchingPickup = false;
  bool _isSearchingDropoff = false;
  bool _isLoadingCurrentLocation = false;
  List<PlacePrediction> _pickupPredictions = [];
  List<PlacePrediction> _dropoffPredictions = [];

  // Selected locations with coordinates
  SelectedLocation? _pickupLocation;
  SelectedLocation? _dropoffLocation;

  // Which field is currently active for search
  bool _isPickupFieldActive = true;

  // Debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Listen to text changes for search
    pickupController.addListener(() => _onSearchChanged(true));
    dropoffController.addListener(() => _onSearchChanged(false));

    // Track focus changes
    pickupFocusNode.addListener(() {
      if (pickupFocusNode.hasFocus) {
        setState(() => _isPickupFieldActive = true);
      }
    });
    dropoffFocusNode.addListener(() {
      if (dropoffFocusNode.hasFocus) {
        setState(() => _isPickupFieldActive = false);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    pickupController.dispose();
    dropoffController.dispose();
    pickupFocusNode.dispose();
    dropoffFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);

    try {
      // First try to get last known location (faster)
      final lastPosition = await _placesService.getLastKnownLocation();
      if (lastPosition != null && mounted) {
        final address = await _placesService.getAddressFromCoordinates(
          lastPosition.latitude,
          lastPosition.longitude,
        );

        if (mounted && address != null) {
          setState(() {
            _pickupLocation = SelectedLocation(
              address: address,
              name: 'Current Location',
              lat: lastPosition.latitude,
              lng: lastPosition.longitude,
            );
            pickupController.text = address;
          });
        }
      }

      // Then get accurate current location
      final position = await _placesService.getCurrentLocation();
      if (position != null) {
        final address = await _placesService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted && address != null) {
          setState(() {
            _pickupLocation = SelectedLocation(
              address: address,
              name: 'Current Location',
              lat: position.latitude,
              lng: position.longitude,
            );
            pickupController.text = address;
          });
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }
  }

  void _onSearchChanged(bool isPickup) {
    _debounceTimer?.cancel();

    final query = (isPickup ? pickupController.text : dropoffController.text)
        .trim();

    if (query.length < 2) {
      setState(() {
        if (isPickup) {
          _pickupPredictions = [];
          _isSearchingPickup = false;
        } else {
          _dropoffPredictions = [];
          _isSearchingDropoff = false;
        }
      });
      return;
    }

    setState(() {
      if (isPickup) {
        _isSearchingPickup = true;
      } else {
        _isSearchingDropoff = true;
      }
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query, isPickup);
    });
  }

  Future<void> _searchPlaces(String query, bool isPickup) async {
    final predictions = await _placesService.searchPlaces(
      query,
      sessionToken: _sessionToken,
    );

    if (mounted) {
      final currentQuery =
          (isPickup ? pickupController.text : dropoffController.text).trim();
      if (currentQuery != query.trim()) return;

      setState(() {
        if (isPickup) {
          _pickupPredictions = predictions;
          _isSearchingPickup = false;
        } else {
          _dropoffPredictions = predictions;
          _isSearchingDropoff = false;
        }
      });
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction, bool isPickup) async {
    // Get place details
    final details = await _placesService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
      fallbackQuery: prediction.description,
    );

    if (details != null) {
      final location = SelectedLocation(
        address: details.formattedAddress,
        name: details.name,
        lat: details.lat,
        lng: details.lng,
        placeId: details.placeId,
      );

      setState(() {
        if (isPickup) {
          _pickupLocation = location;
          pickupController.text = details.formattedAddress;
          _pickupPredictions = [];
          // Move focus to dropoff
          FocusScope.of(context).requestFocus(dropoffFocusNode);
        } else {
          _dropoffLocation = location;
          dropoffController.text = details.formattedAddress;
          _dropoffPredictions = [];
        }
      });

      // Generate new session token after selection
      _sessionToken = const Uuid().v4();
    }
  }

  void _useCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);

    try {
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Enable',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        setState(() => _isLoadingCurrentLocation = false);
        return;
      }

      // Step 2: Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Please allow location access.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoadingCurrentLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permission permanently denied. Please enable in app settings.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        setState(() => _isLoadingCurrentLocation = false);
        return;
      }

      Position? position;

      // Prime attempt: Try using position stream for better accuracy
      try {
        print('Attempting to get position using stream...');
        position = await _placesService.getPositionWithStream();
        if (position != null) {
          print(
            'Got position from stream: ${position.latitude}, ${position.longitude}',
          );
        }
      } catch (e) {
        print('Position stream failed: $e');
      }

      // If stream failed, try direct methods
      if (position == null) {
        // First try: High accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 30),
          );
        } catch (e) {
          print('High accuracy failed: $e');
          // Second try: Best accuracy
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best,
              timeLimit: const Duration(seconds: 30),
            );
          } catch (e2) {
            print('Best accuracy failed: $e2');
            // Third try: Medium accuracy
            try {
              position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 20),
              );
            } catch (e3) {
              print('Medium accuracy failed: $e3');
              // Fourth try: Low accuracy
              try {
                position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.low,
                  timeLimit: const Duration(seconds: 15),
                );
              } catch (e4) {
                print('Low accuracy failed: $e4');
                // Last resort: Last known position
                position = await Geolocator.getLastKnownPosition();
                if (position != null) {
                  print('Using last known position');
                }
              }
            }
          }
        }
      }

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get your location. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isLoadingCurrentLocation = false);
        return;
      }

      // Step 4: Get address from coordinates
      final address = await _placesService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted && address != null) {
        final location = SelectedLocation(
          address: address,
          name: 'Current Location',
          lat: position.latitude,
          lng: position.longitude,
        );

        setState(() {
          if (_isPickupFieldActive) {
            _pickupLocation = location;
            pickupController.text = address;
            _pickupPredictions = [];
          } else {
            _dropoffLocation = location;
            dropoffController.text = address;
            _dropoffPredictions = [];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detected successfully!'),
            backgroundColor: Color(0xFF0D7D8F),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        // Even if address fetch fails, we still have coordinates
        final location = SelectedLocation(
          address:
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          name: 'Current Location',
          lat: position.latitude,
          lng: position.longitude,
        );

        setState(() {
          if (_isPickupFieldActive) {
            _pickupLocation = location;
            pickupController.text = 'Current Location';
            _pickupPredictions = [];
          } else {
            _dropoffLocation = location;
            dropoffController.text = 'Current Location';
            _dropoffPredictions = [];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detected (address unavailable)'),
            backgroundColor: Color(0xFF0D7D8F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        String errorMsg = 'Location error';
        if (e.toString().contains('permission')) {
          errorMsg = 'Location permission required';
        } else if (e.toString().contains('timeout')) {
          errorMsg = 'Location request timed out. Please try again.';
        } else if (e.toString().contains('service')) {
          errorMsg = 'Location service not available';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoadingCurrentLocation = false);
    }
  }

  void _openMapPicker() async {
    final result = await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _isPickupFieldActive
              ? _pickupLocation
              : _dropoffLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (_isPickupFieldActive) {
          _pickupLocation = result;
          pickupController.text = result.address;
          _pickupPredictions = [];
        } else {
          _dropoffLocation = result;
          dropoffController.text = result.address;
          _dropoffPredictions = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPickupTimeSelector(),
                    const SizedBox(height: 16),
                    _buildLocationInputs(),
                    const SizedBox(height: 8),

                    // Show search results or suggestions
                    if (_isPickupFieldActive && _pickupPredictions.isNotEmpty)
                      _buildSearchResults(_pickupPredictions, true)
                    else if (!_isPickupFieldActive &&
                        _dropoffPredictions.isNotEmpty)
                      _buildSearchResults(_dropoffPredictions, false)
                    else
                      _buildLocationSuggestions(),
                  ],
                ),
              ),
            ),

            // Continue button
            if (_pickupLocation != null && _dropoffLocation != null)
              _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Where's it going?",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPickupTimeSelector() {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showPickupTimeOptions(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: onPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                selectedPickupTime ?? 'Pick up now',
                style: TextStyle(
                  color: onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, color: onPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInputs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.34)
        : Colors.black.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 17,
            top: 44,
            bottom: 44,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.22),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Column(
            children: [
              _buildLocationInputField(
                controller: pickupController,
                focusNode: pickupFocusNode,
                label: 'Pickup',
                hint: 'Pickup location',
                isActive: _isPickupFieldActive,
                isSearching: _isSearchingPickup || _isLoadingCurrentLocation,
                onClear: () {
                  pickupController.clear();
                  setState(() {
                    _pickupLocation = null;
                    _pickupPredictions = [];
                  });
                },
                locationIcon: Icons.my_location,
                showCheckmark: _pickupLocation != null,
              ),
              const SizedBox(height: 10),
              _buildLocationInputField(
                controller: dropoffController,
                focusNode: dropoffFocusNode,
                label: 'Recipient',
                hint: "Recipient's location",
                isActive: !_isPickupFieldActive,
                isSearching: _isSearchingDropoff,
                onClear: () {
                  dropoffController.clear();
                  setState(() {
                    _dropoffLocation = null;
                    _dropoffPredictions = [];
                  });
                },
                locationIcon: Icons.location_on,
                showCheckmark: _dropoffLocation != null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isActive,
    required bool isSearching,
    required VoidCallback onClear,
    required IconData locationIcon,
    required bool showCheckmark,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText =
        theme.textTheme.bodySmall?.color ?? onSurface.withOpacity(0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => focusNode.requestFocus(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.primaryColor
                  : theme.primaryColor.withOpacity(isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              locationIcon,
              color: isActive ? Colors.white : theme.primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.primaryColor.withOpacity(isDark ? 0.13 : 0.08)
                    : onSurface.withOpacity(isDark ? 0.045 : 0.035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? theme.primaryColor.withOpacity(0.55)
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isActive
                                ? theme.primaryColor
                                : secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.only(top: 4),
                            hintText: hint,
                            hintStyle: TextStyle(
                              color: secondaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSearching)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  else if (controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close, color: secondaryText, size: 18),
                      onPressed: onClear,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    )
                  else if (showCheckmark)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 21,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<PlacePrediction> predictions, bool isPickup) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.12);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText =
        theme.textTheme.bodySmall?.color ?? onSurface.withOpacity(0.7);
    final dividerColor = theme.dividerColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Search Results',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Divider(height: 1, color: dividerColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: predictions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: dividerColor.withOpacity(0.7)),
            itemBuilder: (context, index) {
              final prediction = predictions[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF0D7D8F),
                    size: 20,
                  ),
                ),
                title: Text(
                  prediction.mainText,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  prediction.secondaryText,
                  style: TextStyle(color: secondaryText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: secondaryText,
                  size: 20,
                ),
                onTap: () => _selectPlace(prediction, isPickup),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSuggestions() {
    return Column(
      children: [
        // Quick Actions Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use Current Location
              _buildQuickActionItem(
                icon: Icons.my_location,
                title: 'Use current location',
                subtitle: 'Detect automatically',
                isLoading: _isLoadingCurrentLocation,
                onTap: _isLoadingCurrentLocation ? null : _useCurrentLocation,
              ),
              const SizedBox(height: 8),
              // Set Location on Map
              _buildQuickActionItem(
                icon: Icons.map_outlined,
                title: 'Set location on map',
                subtitle: 'Choose from map',
                isLoading: false,
                onTap: _openMapPicker,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        const SizedBox(height: 16),

        // Popular Destinations Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular destinations',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall!.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildPopularDestination(
                'Varendra University',
                'Choto Bongram, Rajshahi',
                Icons.school_outlined,
              ),
              const SizedBox(height: 8),
              _buildPopularDestination(
                'Rajshahi University of Engineering & Technology',
                'Station Rd, Rajshahi',
                Icons.school_outlined,
              ),
              const SizedBox(height: 8),
              _buildPopularDestination(
                'Shaheb Bazar',
                'Rajshahi City Center',
                Icons.store_outlined,
              ),
              const SizedBox(height: 8),
              _buildPopularDestination(
                'Rajshahi Railway Station',
                'Station Rd, Rajshahi',
                Icons.train_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge!.color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: secondaryText, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: secondaryText, size: 24),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPopularDestination(
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    // Hardcoded fallback coordinates for popular destinations
    final Map<String, Map<String, dynamic>> fallbackLocations = {
      'Varendra University': {
        'lat': 24.3639,
        'lng': 88.6410,
        'address': 'Varendra University, Choto Bongram, Rajshahi',
        'name': 'Varendra University',
      },
      'Rajshahi University of Engineering & Technology': {
        'lat': 24.3636,
        'lng': 88.6241,
        'address':
            'Rajshahi University of Engineering & Technology, Station Rd, Rajshahi',
        'name': 'Rajshahi University of Engineering & Technology',
      },
      'Shaheb Bazar': {
        'lat': 24.3704,
        'lng': 88.5638,
        'address': 'Shaheb Bazar, Rajshahi City Center',
        'name': 'Shaheb Bazar',
      },
      'Rajshahi Railway Station': {
        'lat': 24.3672,
        'lng': 88.6021,
        'address': 'Rajshahi Railway Station, Station Rd, Rajshahi',
        'name': 'Rajshahi Railway Station',
      },
    };

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyLarge!.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: secondaryText, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: secondaryText, size: 20),
        onTap: () async {
          // Search for this place
          final predictions = await _placesService.searchPlaces(title);
          if (predictions.isNotEmpty) {
            _selectPlace(predictions.first, !_isPickupFieldActive);
          } else if (fallbackLocations.containsKey(title)) {
            // Use fallback coordinates if API fails
            final loc = fallbackLocations[title]!;
            final location = SelectedLocation(
              address: loc['address'],
              name: loc['name'],
              lat: loc['lat'],
              lng: loc['lng'],
              placeId: null,
            );
            setState(() {
              if (!_isPickupFieldActive) {
                _dropoffLocation = location;
                dropoffController.text = location.address;
                _dropoffPredictions = [];
              } else {
                _pickupLocation = location;
                pickupController.text = location.address;
                _pickupPredictions = [];
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected "$title" ✓'),
                backgroundColor: const Color(0xFF0D7D8F),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No results found for "$title".'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _proceedToPackageDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _showPickupTimeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When to pick up?',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTimeOption(
                'Pick up now',
                isSelected: selectedPickupTime == 'Pick up now',
              ),
              _buildTimeOption(
                'Schedule for later',
                isSelected: selectedPickupTime == 'Schedule for later',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeOption(String title, {bool isSelected = false}) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF0D7D8F))
          : null,
      onTap: () {
        setState(() => selectedPickupTime = title);
        Navigator.pop(context);
      },
    );
  }

  void _proceedToPackageDetails() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pickup and dropoff locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if pickup and dropoff locations are the same
    final pickupLat = _pickupLocation!.lat;
    final pickupLng = _pickupLocation!.lng;
    final dropoffLat = _dropoffLocation!.lat;
    final dropoffLng = _dropoffLocation!.lng;

    // Compare coordinates with a small tolerance for floating point comparison
    const double tolerance = 0.0001;
    final isSameLocation =
        (pickupLat - dropoffLat).abs() < tolerance &&
        (pickupLng - dropoffLng).abs() < tolerance;

    if (isSameLocation) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Same Location',
                style: TextStyle(
                  color: Color(0xFF0D7D8F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Pickup and dropoff locations are the same. Please select different locations.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Change Location',
                style: TextStyle(
                  color: Color(0xFF0D7D8F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailsScreen(
          pickupLocation: _pickupLocation!,
          dropoffLocation: _dropoffLocation!,
          pickupTime: selectedPickupTime ?? 'Pick up now',
          isSending: widget.isSending,
        ),
      ),
    );
  }
}

// Package Details Screen - Professional with pricing
class PackageDetailsScreen extends StatefulWidget {
  final SelectedLocation pickupLocation;
  final SelectedLocation dropoffLocation;
  final String pickupTime;
  final bool isSending;

  const PackageDetailsScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    this.isSending = true,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final GooglePlacesService _placesService = GooglePlacesService();
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController senderPhoneController = TextEditingController();
  final TextEditingController senderNidController = TextEditingController();
  final TextEditingController recipientNameController = TextEditingController();
  final TextEditingController recipientPhoneController =
      TextEditingController();
  final TextEditingController recipientNidController = TextEditingController();
  final TextEditingController packageDescriptionController =
      TextEditingController();

  String selectedPackageSize = 'Small';
  DistanceInfo? _distanceInfo;
  double _estimatedPrice = 0;
  bool _isLoadingDistance = true;

  // User profile data
  String _userName = '';
  String _userPhone = '';
  String _userNid = '';
  bool _isPhoneEditable = false;
  bool _isNidEditable = false;

  final List<Map<String, dynamic>> packageSizes = [
    {
      'size': 'Small',
      'description': 'Fits in a bag',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'size': 'Medium',
      'description': 'Fits in a car seat',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'size': 'Large',
      'description': 'Fits in a trunk',
      'icon': Icons.local_shipping_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateDistance();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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

      if (uid != null && uid.isNotEmpty) {
        final doc = await DatabaseMethods().getUserDetail(uid);
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userName = data['Name'] ?? '';
            _userPhone = data['Phone'] ?? '';
            _userNid = data['NID'] ?? '';

            // Always allow editing phone and NID (new or existing users)
            _isPhoneEditable = true;
            _isNidEditable = true;

            if (widget.isSending) {
              // Sending: Auto-fill sender details
              senderNameController.text = _userName;
              senderPhoneController.text = _userPhone;
              senderNidController.text = _userNid;
            } else {
              // Receiving: Auto-fill recipient details (which are "My Details" in receiving mode)
              recipientNameController.text = _userName;
              recipientPhoneController.text = _userPhone;
              recipientNidController.text = _userNid;
            }
          });
        } else {
          // User doc doesn't exist: new user
          setState(() {
            _isPhoneEditable = true;
            _isNidEditable = true;
          });
        }
      } else {
        // No user found: new user
        setState(() {
          _isPhoneEditable = true;
          _isNidEditable = true;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // On error, allow editing
      setState(() {
        _isPhoneEditable = true;
        _isNidEditable = true;
      });
    }
  }

  @override
  void dispose() {
    senderNameController.dispose();
    senderPhoneController.dispose();
    senderNidController.dispose();
    recipientNameController.dispose();
    recipientPhoneController.dispose();
    recipientNidController.dispose();
    packageDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _calculateDistance() async {
    setState(() => _isLoadingDistance = true);

    // Debug logging for coordinates
    print('=== Distance Calculation Debug ===');
    print('Pickup: ${widget.pickupLocation.lat}, ${widget.pickupLocation.lng}');
    print('Pickup Address: ${widget.pickupLocation.address}');
    print(
      'Dropoff: ${widget.dropoffLocation.lat}, ${widget.dropoffLocation.lng}',
    );
    print('Dropoff Address: ${widget.dropoffLocation.address}');

    final distanceInfo = await _placesService.getDistance(
      widget.pickupLocation.lat,
      widget.pickupLocation.lng,
      widget.dropoffLocation.lat,
      widget.dropoffLocation.lng,
    );
    print(
      'Distance Result: ${distanceInfo?.distanceText ?? "null"}, ${distanceInfo?.durationText ?? "null"}',
    );
    print('=== End Debug ===');

    if (mounted) {
      setState(() {
        _distanceInfo = distanceInfo;
        _isLoadingDistance = false;
        _updatePrice();
      });
    }
  }

  void _updatePrice() {
    if (_distanceInfo != null) {
      _estimatedPrice = _placesService.calculateDeliveryPrice(
        _distanceInfo!.distanceValue,
        selectedPackageSize,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteSummary(),
                    const SizedBox(height: 20),
                    _buildPackageSizeSelection(),
                    const SizedBox(height: 24),
                    if (widget.isSending) ...[
                      // Sending: Show sender (auto-filled) then recipient (editable)
                      _buildSectionTitle('Your details'),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: senderNameController,
                        hint: 'Your name',
                        icon: Icons.person_outline,
                        enabled: true,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: senderPhoneController,
                        hint: 'Your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        enabled: _isPhoneEditable,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: senderNidController,
                        hint: 'Your NID',
                        icon: Icons.badge_outlined,
                        enabled: _isNidEditable,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Recipient details'),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: recipientNameController,
                        hint: 'Recipient name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: recipientPhoneController,
                        hint: 'Recipient phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ] else ...[
                      // Receiving: Show recipient (auto-filled) then sender (editable)
                      _buildSectionTitle('Your details'),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: recipientNameController,
                        hint: 'Your name',
                        icon: Icons.person_outline,
                        enabled: true,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: recipientPhoneController,
                        hint: 'Your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        enabled: _isPhoneEditable,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: recipientNidController,
                        hint: 'Your NID',
                        icon: Icons.badge_outlined,
                        enabled: _isNidEditable,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Sender details'),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: senderNameController,
                        hint: 'Sender name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: senderPhoneController,
                        hint: 'Sender phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle('Package description'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: packageDescriptionController,
                      hint: "What's inside?",
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildPriceAndConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: theme.primaryColor, size: 28),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Package details',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRouteSummary() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final dividerColor = theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 2, height: 35, color: dividerColor),
                  const Icon(Icons.location_on, color: Colors.orange, size: 20),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pickupLocation.address,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.dropoffLocation.address,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Distance and duration info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                icon: Icons.straighten,
                label: 'Distance',
                value: _isLoadingDistance
                    ? '...'
                    : _distanceInfo?.distanceText ?? 'N/A',
              ),
              Container(width: 1, height: 30, color: dividerColor),
              _buildInfoChip(
                icon: Icons.access_time,
                label: 'Est. Time',
                value: _isLoadingDistance
                    ? '...'
                    : _distanceInfo?.durationText ?? 'N/A',
              ),
              Container(width: 1, height: 30, color: dividerColor),
              _buildInfoChip(
                icon: Icons.schedule,
                label: 'Pickup',
                value: widget.pickupTime == 'Pick up now' ? 'Now' : 'Scheduled',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText =
        theme.textTheme.bodySmall?.color ?? onSurface.withOpacity(0.7);

    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: secondaryText, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageSizeSelection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText =
        theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Package size'),
        const SizedBox(height: 12),
        Row(
          children: packageSizes.map((package) {
            final isSelected = selectedPackageSize == package['size'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPackageSize = package['size'] as String;
                    _updatePrice();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor
                        : (theme.inputDecorationTheme.fillColor ??
                              theme.colorScheme.surface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : theme.primaryColor.withOpacity(
                              isDark ? 0.28 : 0.22,
                            ),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (isSelected || !isDark)
                        BoxShadow(
                          color: isSelected
                              ? theme.primaryColor.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        package['icon'] as IconData,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        package['size'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package['description'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withOpacity(0.75)
                              : secondaryText,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        color: theme.primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText =
        theme.textTheme.bodySmall?.color ?? onSurface.withOpacity(0.6);
    final fillColor =
        theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: fillColor,
          prefixIcon: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, color: theme.primaryColor, size: 21),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 52,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: maxLines > 1 ? 18 : 16,
          ),
          hintStyle: TextStyle(
            color: secondaryText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.primaryColor.withOpacity(isDark ? 0.38 : 0.34),
              width: 1.1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.primaryColor.withOpacity(isDark ? 0.38 : 0.34),
              width: 1.1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.primaryColor, width: 1.6),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.primaryColor.withOpacity(isDark ? 0.26 : 0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceAndConfirmButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: isDark ? 10 : 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Price summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? (theme.inputDecorationTheme.fillColor ??
                          theme.colorScheme.surface)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(isDark ? 0.2 : 0.16),
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Price',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoadingDistance
                                ? 'Calculating...'
                                : '৳ ${_estimatedPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          selectedPackageSize,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Confirm button
            AppWidget.primaryActionButton(
              context: context,
              label: 'Confirm & Find Driver',
              loading: _isLoadingDistance,
              width: double.infinity,
              icon: Icons.local_shipping_rounded,
              onPressed: _isLoadingDistance ? null : _confirmOrder,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmOrder() {
    if (senderNameController.text.isEmpty ||
        senderPhoneController.text.isEmpty ||
        recipientNameController.text.isEmpty ||
        recipientPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (packageDescriptionController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                'Description Required',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Please describe what\'s inside the package. This helps the driver and recipient know what to expect.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Add Description',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Show Order Summary dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Order Summary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Package Size', selectedPackageSize),
            _buildSummaryRow('Distance', _distanceInfo?.distanceText ?? 'N/A'),
            _buildSummaryRow('Est. Time', _distanceInfo?.durationText ?? 'N/A'),
            _buildSummaryRow(
              'Price',
              '৳ ${_estimatedPrice.toStringAsFixed(0)}',
            ),
            const Divider(),
            _buildSummaryRow('Sender', senderNameController.text),
            _buildSummaryRow('Recipient', recipientNameController.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleOrderConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOrderConfirmation() async {
    try {
      // Check Firebase authentication
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        // User is already logged in, check if they have an account in database
        final helper = SharedpreferenceHelper();
        String? userId = await helper.getUserId();

        if (userId == null || userId.isEmpty) {
          // Try to get userId from Firebase UID
          final byUid = await DatabaseMethods().getUserByFirebaseUid(user.uid);
          if (byUid.docs.isNotEmpty) {
            userId = byUid.docs.first.id;
            await helper.saveUserId(userId);
          }
        }

        if (userId != null && userId.isNotEmpty) {
          // User has account - proceed with order placement
          final orderId = 'QP-${DateTime.now().millisecondsSinceEpoch}';
          await _placeOrder(
            orderId: orderId,
            paymentStatus: 'Unpaid',
            paymentMethod: 'Pending',
            paymentProvider: '',
            paidAmount: 0,
          );
        } else {
          // User logged in but no account in database - treat as new user
          await _proceedToSignup();
        }
      } else {
        // User not logged in - proceed to signup
        await _proceedToSignup();
      }
    } catch (e) {
      print('Error in order confirmation: $e');
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

  Future<void> _proceedToSignup() async {
    try {
      // Create OrderData object
      final orderData = OrderData(
        senderName: senderNameController.text.trim(),
        senderPhone: senderPhoneController.text.trim(),
        senderNid: senderNidController.text.trim(),
        recipientName: recipientNameController.text.trim(),
        recipientPhone: recipientPhoneController.text.trim(),
        recipientNid: recipientNidController.text.trim(),
        pickupAddress: widget.pickupLocation.address,
        dropoffAddress: widget.dropoffLocation.address,
        pickupLat: widget.pickupLocation.lat,
        pickupLng: widget.pickupLocation.lng,
        dropoffLat: widget.dropoffLocation.lat,
        dropoffLng: widget.dropoffLocation.lng,
        packageSize: selectedPackageSize,
        packageDescription: packageDescriptionController.text.trim(),
        distance: _distanceInfo?.distanceText ?? 'N/A',
        estimatedTime: _distanceInfo?.durationText ?? 'N/A',
        estimatedPrice: _estimatedPrice,
        pickupTime: widget.pickupTime,
      );

      // Save pending order
      await PendingOrderService.savePendingOrder(orderData);

      if (mounted) {
        // Navigate to signup with pre-filled data
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpScreen(pendingOrderData: orderData),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error proceeding to signup: $e');
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

  Future<void> _placeOrder({
    required String orderId,
    required String paymentStatus,
    required String paymentMethod,
    required String paymentProvider,
    required double paidAmount,
    String? transactionId,
  }) async {
    try {
      final helper = SharedpreferenceHelper();
      final userId = await helper.getUserId();
      if (userId == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      final orderData = {
        'OrderId': orderId,
        'UserId': userId,
        'SenderName': senderNameController.text.trim(),
        'SenderPhone': senderPhoneController.text.trim(),
        'ReceiverName': recipientNameController.text.trim(),
        'ReceiverPhone': recipientPhoneController.text.trim(),
        'PickupAddress': widget.pickupLocation.address,
        'DropoffAddress': widget.dropoffLocation.address,
        'PackageSize': selectedPackageSize,
        'PackageDescription': packageDescriptionController.text.trim(),
        'Distance': _distanceInfo?.distanceText ?? 'N/A',
        'EstimatedTime': _distanceInfo?.durationText ?? 'N/A',
        'Price': _estimatedPrice.toStringAsFixed(0),
        'PaymentStatus': paymentStatus,
        'PaymentMethod': paymentMethod,
        'PaymentProvider': paymentProvider,
        'PaidAmount': paidAmount.toStringAsFixed(0),
        'TransactionId': transactionId ?? '',
        'Status': 'Pending',
        'CreatedAt': DateTime.now().toIso8601String(),
      };

      await DatabaseMethods().addUserOrder(orderData, userId, orderId);
      await DatabaseMethods().addAdminOrder(orderData, orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  'Order placed successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );

        // Navigate to Find Driver screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FindDriverScreen(
              orderId: orderId,
              pickupLat: widget.pickupLocation.lat.toString(),
              pickupLng: widget.pickupLocation.lng.toString(),
              dropoffLat: widget.dropoffLocation.lat.toString(),
              dropoffLng: widget.dropoffLocation.lng.toString(),
              pickupAddress: widget.pickupLocation.address,
              dropoffAddress: widget.dropoffLocation.address,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: secondaryText, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Map Picker Screen - Professional Google Maps Based Location Picker
class MapPickerScreen extends StatefulWidget {
  final SelectedLocation? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final GooglePlacesService _placesService = GooglePlacesService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  Timer? _debounceTimer;
  String _sessionToken = const Uuid().v4();

  // Selected location
  double _selectedLat = 24.3636; // Default: Rajshahi
  double _selectedLng = 88.6241;
  String _selectedAddress = '';
  String _selectedName = '';

  // Google Map
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      if (widget.initialLocation != null) {
        _selectedLat = widget.initialLocation!.lat;
        _selectedLng = widget.initialLocation!.lng;
        _selectedAddress = widget.initialLocation!.address;
        _selectedName = widget.initialLocation!.name;
        _searchController.text = widget.initialLocation!.address;
      } else {
        // Try to get user's current location first
        debugPrint('Trying to load user current location...');
        final currentPosition = await _placesService.getCurrentLocation();

        if (currentPosition != null && mounted) {
          debugPrint(
            'Got current position: ${currentPosition.latitude}, ${currentPosition.longitude}',
          );
          _selectedLat = currentPosition.latitude;
          _selectedLng = currentPosition.longitude;

          // Get address from coordinates
          final address = await _placesService.getAddressFromCoordinates(
            currentPosition.latitude,
            currentPosition.longitude,
          );

          if (address != null && mounted) {
            _selectedAddress = address;
            _selectedName = 'Current Location';
            _searchController.text = address;
          }
        } else {
          // Fallback to default Rajshahi location
          debugPrint('Using default Rajshahi location');
          await _loadAddressForCoordinates(_selectedLat, _selectedLng);
        }
      }
      if (mounted) {
        _updateMarker();
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      if (mounted) {
        _updateMarker();
      }
    }
  }

  Future<void> _loadAddressForCoordinates(double lat, double lng) async {
    try {
      final address = await _placesService.getAddressFromCoordinates(lat, lng);
      if (mounted && address != null) {
        setState(() {
          _selectedAddress = address;
          _selectedName = address.split(',').first;
          _searchController.text = _selectedName;
          _predictions = [];
        });
        _updateMarker();
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker() {
    try {
      if (!mounted) return;

      final marker = Marker(
        markerId: const MarkerId('selected-location'),
        position: LatLng(_selectedLat, _selectedLng),
        infoWindow: InfoWindow(
          title: _selectedName.isNotEmpty ? _selectedName : 'Selected Location',
          snippet: _selectedAddress.isNotEmpty
              ? _selectedAddress
              : 'Location selected',
        ),
      );

      setState(() {
        _markers = {marker};
      });
    } catch (e) {
      debugPrint('Error updating marker: $e');
    }
  }

  Future<void> _moveCameraToSelectedLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(_selectedLat, _selectedLng), zoom: 17),
        ),
      );
    } catch (e) {
      debugPrint('Error moving map camera: $e');
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmedQuery = query.trim();
    debugPrint(
      'Search changed: "$trimmedQuery" (length: ${trimmedQuery.length})',
    );

    if (trimmedQuery.length < 2) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(trimmedQuery);
    });
  }

  Future<void> _searchPlaces(String query) async {
    try {
      debugPrint('Searching for: $query');
      final predictions = await _placesService.searchPlaces(
        query,
        sessionToken: _sessionToken,
      );

      debugPrint('Got ${predictions.length} predictions');
      if (mounted) {
        if (_searchController.text.trim() != query.trim()) return;

        setState(() {
          _predictions = predictions;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Search unavailable. Please try using current location or map.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() => _isLoadingLocation = true);

    final details = await _placesService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
      fallbackQuery: prediction.description,
    );

    if (details != null && mounted) {
      setState(() {
        _selectedLat = details.lat;
        _selectedLng = details.lng;
        _selectedAddress = details.formattedAddress;
        _selectedName = prediction.mainText;
        _searchController.text = prediction.mainText;
        _predictions = [];
        _isLoadingLocation = false;
      });

      // Update marker on map
      _updateMarker();
      _moveCameraToSelectedLocation();

      // New session token
      _sessionToken = const Uuid().v4();

      // Hide keyboard
      FocusScope.of(context).unfocus();
    } else {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Enable',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null && mounted) {
        final address = await _placesService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _selectedLat = position!.latitude;
          _selectedLng = position.longitude;
          _selectedAddress =
              address ??
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _selectedName = 'Current Location';
          _searchController.text = 'Current Location';
        });

        // Update marker on map
        _updateMarker();
        _moveCameraToSelectedLocation();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detected'),
            backgroundColor: Color(0xFF0D7D8F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Location error: $e');
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _confirmLocation() {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final location = SelectedLocation(
      address: _selectedAddress,
      name: _selectedName.isNotEmpty ? _selectedName : 'Selected Location',
      lat: _selectedLat,
      lng: _selectedLng,
    );

    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.primaryColor,
                          size: 26,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Select Location',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Search field
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color:
                          theme.inputDecorationTheme.fillColor ??
                          theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.14)
                            : const Color(0xFF172F35).withOpacity(0.72),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            theme.brightness == Brightness.dark ? 0.3 : 0.12,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for a place...',
                        hintStyle: TextStyle(color: secondaryText),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.primaryColor,
                        ),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: secondaryText),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _predictions = []);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search results or map and location info
            Expanded(
              child: Builder(
                builder: (context) {
                  debugPrint(
                    'Building expanded area - predictions count: ${_predictions.length}, searching: $_isSearching',
                  );
                  if (_predictions.isNotEmpty) {
                    return _buildSearchResults();
                  } else {
                    return _buildMapArea();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Stack(
      children: [
        // Google Map with error handling
        Container(
          color: theme.scaffoldBackgroundColor,
          child: GoogleMap(
            onMapCreated: (controller) {
              try {
                _mapController = controller;
              } catch (e) {
                debugPrint('Error creating map: $e');
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(_selectedLat, _selectedLng),
              zoom: 16,
            ),
            markers: _markers,
            onTap: (LatLng position) {
              try {
                setState(() {
                  _selectedLat = position.latitude;
                  _selectedLng = position.longitude;
                });
                _loadAddressForCoordinates(
                  position.latitude,
                  position.longitude,
                );
              } catch (e) {
                debugPrint('Error on map tap: $e');
              }
            },
            compassEnabled: true,
            myLocationEnabled:
                false, // Changed to false to avoid permission issues
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            liteModeEnabled: false,
            indoorViewEnabled: false,
            fortyFiveDegreeImageryEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
          ),
        ),

        // Bottom action buttons
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingLocation ? null : _useCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0D7D8F),
                              ),
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Current Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _confirmLocation,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Location info card at top
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Location',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress.isNotEmpty
                      ? _selectedAddress
                      : 'Default Location: Rajshahi',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);
    final secondaryText =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _predictions.length,
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                prediction.mainText,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                prediction.secondaryText,
                style: TextStyle(color: secondaryText, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: secondaryText,
                size: 20,
              ),
              onTap: () => _selectPlace(prediction),
            ),
          );
        },
      ),
    );
  }
}

// Model class for selected locations
class SelectedLocation {
  final String address;
  final String name;
  final double lat;
  final double lng;
  final String? placeId;

  SelectedLocation({
    required this.address,
    required this.name,
    required this.lat,
    required this.lng,
    this.placeId,
  });
}
