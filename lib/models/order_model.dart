class OrderData {
  final String? senderName;
  final String? senderPhone;
  final String? senderEmail;
  final String? senderNid;
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientNid;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String packageSize;
  final String packageDescription;
  final String distance;
  final String estimatedTime;
  final double estimatedPrice;
  final String pickupTime;

  OrderData({
    this.senderName,
    this.senderPhone,
    this.senderEmail,
    this.senderNid,
    this.recipientName,
    this.recipientPhone,
    this.recipientNid,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.packageSize,
    required this.packageDescription,
    required this.distance,
    required this.estimatedTime,
    required this.estimatedPrice,
    required this.pickupTime,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'senderName': senderName,
        'senderPhone': senderPhone,
        'senderEmail': senderEmail,
        'senderNid': senderNid,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'recipientNid': recipientNid,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'packageSize': packageSize,
        'packageDescription': packageDescription,
        'distance': distance,
        'estimatedTime': estimatedTime,
        'estimatedPrice': estimatedPrice,
        'pickupTime': pickupTime,
      };

  // Create from JSON
  factory OrderData.fromJson(Map<String, dynamic> json) => OrderData(
        senderName: json['senderName'] as String?,
        senderPhone: json['senderPhone'] as String?,
        senderEmail: json['senderEmail'] as String?,
        senderNid: json['senderNid'] as String?,
        recipientName: json['recipientName'] as String?,
        recipientPhone: json['recipientPhone'] as String?,
        recipientNid: json['recipientNid'] as String?,
        pickupAddress: json['pickupAddress'] as String? ?? '',
        dropoffAddress: json['dropoffAddress'] as String? ?? '',
        pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 0.0,
        pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 0.0,
        dropoffLat: (json['dropoffLat'] as num?)?.toDouble() ?? 0.0,
        dropoffLng: (json['dropoffLng'] as num?)?.toDouble() ?? 0.0,
        packageSize: json['packageSize'] as String? ?? 'Small',
        packageDescription: json['packageDescription'] as String? ?? '',
        distance: json['distance'] as String? ?? '',
        estimatedTime: json['estimatedTime'] as String? ?? '',
        estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
        pickupTime: json['pickupTime'] as String? ?? 'Pick up now',
      );
}
