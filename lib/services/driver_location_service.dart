import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:quick_parcel/services/database.dart';

class DriverLocationService {
  static final DriverLocationService _instance =
      DriverLocationService._internal();

  factory DriverLocationService() {
    return _instance;
  }

  DriverLocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  Timer? _locationUpdateTimer;

  Future<void> startLocationTracking(String driverId) async {
    if (_isTracking) return;

    try {
      // Validate driver ID
      if (driverId.isEmpty) {
        print('Error: Driver ID is empty');
        return;
      }

      // Request location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _isTracking = true;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      await DatabaseMethods().updateDriverLocation(
        driverId,
        position.latitude,
        position.longitude,
      );
      await DatabaseMethods().updateDriverAvailability(driverId, true);

      // Start tracking location - update every 5 seconds
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) async {
          if (!_isTracking) return;
          
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best,
              timeLimit: const Duration(seconds: 10),
            );

            // Update driver location in Firestore
            await DatabaseMethods().updateDriverLocation(
              driverId,
              position.latitude,
              position.longitude,
            );
          } catch (e) {
            print('Error updating driver location: $e');
            // Continue tracking even if location update fails
          }
        },
      );

      print('Location tracking started for driver: $driverId');
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  Future<void> stopLocationTracking(String driverId) async {
    try {
      _locationUpdateTimer?.cancel();
      _isTracking = false;

      if (driverId.isNotEmpty) {
        // Set driver as unavailable
        await DatabaseMethods().updateDriverAvailability(driverId, false);
      }

      print('Location tracking stopped for driver: $driverId');
    } catch (e) {
      print('Error stopping location tracking: $e');
      // Don't rethrow - stopping should always succeed
      _isTracking = false;
    }
  }

  bool get isTracking => _isTracking;

  Future<void> dispose() async {
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _isTracking = false;
  }
}
