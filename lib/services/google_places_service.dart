import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyCTZlFTsXe-3_sVAT0hKt7Uq_DEu7Zzczg';
  static const String _mapsHost = 'maps.googleapis.com';
  static const String _placePath = '/maps/api/place';
  static const double _defaultLat = 24.3636; // Rajshahi
  static const double _defaultLng = 88.6241;
  static const int _defaultSearchRadiusMeters = 50000;

  // Singleton pattern
  static final GooglePlacesService _instance = GooglePlacesService._internal();
  factory GooglePlacesService() => _instance;
  GooglePlacesService._internal();

  // Check and request location permission using Geolocator only
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  // Search places with autocomplete
  Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? sessionToken,
    Position? currentLocation,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) return [];

    try {
      final biasLat = currentLocation?.latitude ?? _defaultLat;
      final biasLng = currentLocation?.longitude ?? _defaultLng;
      final params = <String, String>{
        'input': trimmedQuery,
        'key': _apiKey,
        'components': 'country:bd',
        'language': 'en',
        'region': 'bd',
        'location': '$biasLat,$biasLng',
        'radius': _defaultSearchRadiusMeters.toString(),
        'origin': '$biasLat,$biasLng',
        if (sessionToken != null) 'sessiontoken': sessionToken,
      };

      final url = Uri.https(_mapsHost, '$_placePath/autocomplete/json', params);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final places = predictions
              .map((p) => PlacePrediction.fromJson(p))
              .where((p) => p.placeId.isNotEmpty)
              .toList();
          if (places.isNotEmpty) return places;
        } else if (data['status'] == 'REQUEST_DENIED') {
          print(
            'REQUEST_DENIED: ${data['error_message']} - Check billing/API key',
          );
        } else if (data['status'] != 'ZERO_RESULTS') {
          print(
            'Places API Error: ${data['status']} - ${data['error_message'] ?? ''}',
          );
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }

    final geocodingResults = await _searchPlacesWithGeocoding(trimmedQuery);
    if (geocodingResults.isNotEmpty) return geocodingResults;

    return _searchPlacesWithOpenStreetMap(trimmedQuery);
  }

  // Get place details by place ID
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? fallbackQuery,
  }) async {
    try {
      final osmDetails = _getOpenStreetMapDetails(placeId, fallbackQuery);
      if (osmDetails != null) return osmDetails;

      if (placeId.isNotEmpty) {
        final url = Uri.https(_mapsHost, '$_placePath/details/json', {
          'place_id': placeId,
          'key': _apiKey,
          'fields':
              'formatted_address,geometry,name,place_id,address_components',
          'language': 'en',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        });

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'OK') {
            return PlaceDetails.fromJson(data['result']);
          }
        }
      }

      final geocodedPlace = placeId.isNotEmpty
          ? await _getPlaceDetailsFromGeocodingPlaceId(placeId)
          : null;
      if (geocodedPlace != null) return geocodedPlace;

      if (fallbackQuery != null && fallbackQuery.trim().isNotEmpty) {
        return geocodeAddress(fallbackQuery);
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
    return null;
  }

  Future<List<PlacePrediction>> _searchPlacesWithGeocoding(String query) async {
    try {
      final url = Uri.https(_mapsHost, '/maps/api/geocode/json', {
        'address': '$query, Bangladesh',
        'key': _apiKey,
        'components': 'country:BD',
        'bounds':
            '${_defaultLat - 0.5},${_defaultLng - 0.5}|${_defaultLat + 0.5},${_defaultLng + 0.5}',
        'language': 'en',
        'region': 'bd',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] is List) {
          final seenPlaceIds = <String>{};
          return (data['results'] as List)
              .map((result) => PlacePrediction.fromGeocodingJson(result))
              .where((prediction) {
                final key = prediction.placeId.isNotEmpty
                    ? prediction.placeId
                    : prediction.description;
                return key.isNotEmpty && seenPlaceIds.add(key);
              })
              .toList();
        }
      }
    } catch (e) {
      print('Error geocoding places: $e');
    }
    return [];
  }

  Future<List<PlacePrediction>> _searchPlacesWithOpenStreetMap(
    String query,
  ) async {
    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '8',
        'countrycodes': 'bd',
      });

      final response = await http.get(
        url,
        headers: const {
          'User-Agent': 'quick_parcel_flutter_app/1.0',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final seen = <String>{};
          return data
              .whereType<Map<String, dynamic>>()
              .map((result) => PlacePrediction.fromOpenStreetMapJson(result))
              .where((prediction) {
                final key = prediction.placeId.isNotEmpty
                    ? prediction.placeId
                    : prediction.description;
                return key.isNotEmpty && seen.add(key);
              })
              .toList();
        }
      } else {
        print('OpenStreetMap search error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching OpenStreetMap places: $e');
    }
    return [];
  }

  PlaceDetails? _getOpenStreetMapDetails(
    String placeId,
    String? fallbackQuery,
  ) {
    if (!placeId.startsWith('osm:')) return null;

    final parts = placeId.substring(4).split(',');
    if (parts.length != 2) return null;

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;

    final address = fallbackQuery?.trim();
    final formattedAddress = address != null && address.isNotEmpty
        ? address
        : '$lat, $lng';

    return PlaceDetails(
      placeId: placeId,
      name: formattedAddress.split(',').first,
      formattedAddress: formattedAddress,
      lat: lat,
      lng: lng,
      addressComponents: const [],
    );
  }

  Future<PlaceDetails?> _getPlaceDetailsFromGeocodingPlaceId(
    String placeId,
  ) async {
    try {
      final url = Uri.https(_mapsHost, '/maps/api/geocode/json', {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'en',
      });

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] is List) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            return PlaceDetails.fromGeocodingJson(results.first);
          }
        }
      }
    } catch (e) {
      print('Error getting geocoding place details: $e');
    }
    return null;
  }

  Future<PlaceDetails?> geocodeAddress(String query) async {
    final predictions = await _searchPlacesWithGeocoding(query);
    if (predictions.isEmpty) return null;
    return _getPlaceDetailsFromGeocodingPlaceId(predictions.first.placeId);
  }

  // Get current location with improved error handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Try to get current position with better settings
      try {
        // First try: High accuracy with longer timeout
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
      } catch (e) {
        print('Error getting high accuracy location: $e');
        // Fallback to best accuracy
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 30),
          );
        } catch (e2) {
          print('Error getting best accuracy location: $e2');
          // Fallback to medium accuracy
          try {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 20),
            );
          } catch (e3) {
            print('Error getting medium accuracy location: $e3');
            // Final fallback to low accuracy
            try {
              return await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(seconds: 15),
              );
            } catch (e4) {
              print('Error getting low accuracy location: $e4');
              // Last resort: get last known position
              final lastPosition = await Geolocator.getLastKnownPosition();
              if (lastPosition != null) {
                print('Using last known location');
                return lastPosition;
              }
              return null;
            }
          }
        }
      }
    } catch (e) {
      print('Error in getCurrentLocation: $e');
      return null;
    }
  }

  // Get last known location (faster)
  Future<Position?> getLastKnownLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  // Get position using location stream for best accuracy
  Future<Position?> getPositionWithStream({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        return null;
      }

      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('No location permission');
        return null;
      }

      // Get the position stream and take the first accurate position
      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // Emit all position updates
          timeLimit: Duration(seconds: 30),
        ),
      );

      Position? bestPosition;
      double bestAccuracy = double.infinity;

      await for (final position in positionStream.take(1)) {
        if (position.accuracy < bestAccuracy) {
          bestAccuracy = position.accuracy;
          bestPosition = position;
          print('Got position with accuracy: ${position.accuracy}m');
          break; // Take first position and break
        }
      }

      return bestPosition;
    } catch (e) {
      print('Error in getPositionWithStream: $e');
      return null;
    }
  }

  // Reverse geocoding - get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=$lat,$lng'
        '&key=$_apiKey'
        '&language=en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }

  // Get distance between two points
  Future<DistanceInfo?> getDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      print(
        'Distance API Called: origin($originLat, $originLng) -> dest($destLat, $destLng)',
      );

      // Try API first
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=$originLat,$originLng'
        '&destinations=$destLat,$destLng'
        '&key=$_apiKey'
        '&units=metric',
      );

      final response = await http.get(url);
      print('Distance API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Distance API Response: ${data['status']}');

        if (data['status'] == 'OK') {
          final elements = data['rows'][0]['elements'][0];
          if (elements['status'] == 'OK') {
            return DistanceInfo(
              distanceText: elements['distance']['text'],
              distanceValue: elements['distance']['value'],
              durationText: elements['duration']['text'],
              durationValue: elements['duration']['value'],
            );
          } else {
            print('API returned element status: ${elements['status']}');
          }
        }
      }

      // Fallback: Use Haversine formula to calculate distance
      print('Falling back to Haversine distance calculation');
      return _calculateDistanceHaversine(
        originLat,
        originLng,
        destLat,
        destLng,
      );
    } catch (e) {
      print('Error getting distance: $e');
      // Fallback to Haversine calculation on error
      return _calculateDistanceHaversine(
        originLat,
        originLng,
        destLat,
        destLng,
      );
    }
  }

  // Haversine formula to calculate distance between two coordinates
  DistanceInfo? _calculateDistanceHaversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    try {
      const double earthRadiusKm = 6371.0;

      double dLat = _toRadian(lat2 - lat1);
      double dLon = _toRadian(lon2 - lon1);

      double a =
          (math.sin(dLat / 2) * math.sin(dLat / 2)) +
          math.cos(_toRadian(lat1)) *
              math.cos(_toRadian(lat2)) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);

      double c = 2 * math.asin(math.sqrt(a));
      double distanceKm = earthRadiusKm * c;
      int distanceMeters = (distanceKm * 1000).toInt();

      // Estimate duration (assuming average speed of 20 km/h for Rajshahi traffic)
      double estimatedMinutes = (distanceKm / 20) * 60;
      int durationSeconds = (estimatedMinutes * 60).toInt();

      String distanceText = distanceKm < 1
          ? '${(distanceKm * 1000).toStringAsFixed(0)}m'
          : '${distanceKm.toStringAsFixed(1)} km';

      String durationText = estimatedMinutes < 1
          ? '1 min'
          : estimatedMinutes.toInt() > 60
          ? '${(estimatedMinutes / 60).toStringAsFixed(0)} h ${(estimatedMinutes % 60).toInt()} min'
          : '${estimatedMinutes.toStringAsFixed(0)} min';

      print('Haversine Distance: $distanceText, Duration: $durationText');

      return DistanceInfo(
        distanceText: distanceText,
        distanceValue: distanceMeters,
        durationText: durationText,
        durationValue: durationSeconds,
      );
    } catch (e) {
      print('Error in Haversine calculation: $e');
      return null;
    }
  }

  double _toRadian(double degree) {
    return degree * (3.14159265359 / 180);
  }

  // Calculate delivery price based on distance
  double calculateDeliveryPrice(int distanceInMeters, String packageSize) {
    double basePrice = 50.0; // Base price in BDT
    double perKmRate = 20.0; // Per kilometer rate (updated)

    // Package size multiplier
    double sizeMultiplier = 1.0;
    switch (packageSize.toLowerCase()) {
      case 'small':
        sizeMultiplier = 1.0;
        break;
      case 'medium':
        sizeMultiplier = 1.5;
        break;
      case 'large':
        sizeMultiplier = 2.0;
        break;
    }

    // Prevent division by zero and negative values
    double distanceKm = (distanceInMeters > 0)
        ? (distanceInMeters / 1000)
        : 0.0;
    double price = basePrice + (distanceKm * perKmRate * sizeMultiplier);

    // If distance is zero, set minimum price
    if (distanceKm == 0) {
      price = basePrice;
    }

    return double.parse(price.toStringAsFixed(2));
  }
}

// Models
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? distanceMeters;
  final double? lat;
  final double? lng;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.distanceMeters,
    this.lat,
    this.lng,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    );
  }

  factory PlacePrediction.fromGeocodingJson(Map<String, dynamic> json) {
    final formattedAddress = json['formatted_address'] ?? '';
    final components = json['address_components'] as List? ?? [];
    final mainText = components.isNotEmpty
        ? components.first['long_name'] ?? formattedAddress
        : formattedAddress;
    final secondaryText = formattedAddress
        .toString()
        .replaceFirst(mainText.toString(), '')
        .replaceFirst(RegExp(r'^,\s*'), '');

    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: formattedAddress,
      mainText: mainText.toString(),
      secondaryText: secondaryText,
    );
  }

  factory PlacePrediction.fromOpenStreetMapJson(Map<String, dynamic> json) {
    final displayName = (json['display_name'] ?? '').toString();
    final lat = double.tryParse((json['lat'] ?? '').toString());
    final lng = double.tryParse((json['lon'] ?? '').toString());
    final address = json['address'] is Map ? json['address'] as Map : const {};
    final name = (json['name'] ??
            address['road'] ??
            address['suburb'] ??
            address['village'] ??
            address['town'] ??
            address['city'] ??
            displayName.split(',').first)
        .toString();
    final secondaryText = displayName
        .replaceFirst(name, '')
        .replaceFirst(RegExp(r'^,\s*'), '');

    return PlacePrediction(
      placeId: lat != null && lng != null ? 'osm:$lat,$lng' : '',
      description: displayName,
      mainText: name,
      secondaryText: secondaryText,
      lat: lat,
      lng: lng,
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;
  final List<AddressComponent> addressComponents;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    required this.addressComponents,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    final components = json['address_components'] as List? ?? [];

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      lat: (location['lat'] ?? 0).toDouble(),
      lng: (location['lng'] ?? 0).toDouble(),
      addressComponents: components
          .map((c) => AddressComponent.fromJson(c))
          .toList(),
    );
  }

  factory PlaceDetails.fromGeocodingJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    final components = json['address_components'] as List? ?? [];
    final formattedAddress = json['formatted_address'] ?? '';
    final name = components.isNotEmpty
        ? components.first['long_name'] ?? formattedAddress
        : formattedAddress;

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: name.toString(),
      formattedAddress: formattedAddress,
      lat: (location['lat'] ?? 0).toDouble(),
      lng: (location['lng'] ?? 0).toDouble(),
      addressComponents: components
          .map((c) => AddressComponent.fromJson(c))
          .toList(),
    );
  }
}

class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] ?? '',
      shortName: json['short_name'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

class DistanceInfo {
  final String distanceText;
  final int distanceValue; // in meters
  final String durationText;
  final int durationValue; // in seconds

  DistanceInfo({
    required this.distanceText,
    required this.distanceValue,
    required this.durationText,
    required this.durationValue,
  });
}

// Location model for storing selected locations
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

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'name': name,
      'lat': lat,
      'lng': lng,
      'placeId': placeId,
    };
  }

  factory SelectedLocation.fromMap(Map<String, dynamic> map) {
    return SelectedLocation(
      address: map['address'] ?? '',
      name: map['name'] ?? '',
      lat: map['lat'] ?? 0.0,
      lng: map['lng'] ?? 0.0,
      placeId: map['placeId'],
    );
  }
}
