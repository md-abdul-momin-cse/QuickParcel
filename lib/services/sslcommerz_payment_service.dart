import 'dart:convert';

import 'package:http/http.dart' as http;

class SslCommerzSession {
  final String gatewayUrl;
  final String transactionId;
  final String callbackUrl;

  const SslCommerzSession({
    required this.gatewayUrl,
    required this.transactionId,
    required this.callbackUrl,
  });
}

class SslCommerzPaymentService {
  static const String _baseFunctionUrl =
      'https://us-central1-quickparcel-f0b4e.cloudfunctions.net';

  Future<SslCommerzSession> createSession({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String paymentProvider,
  }) async {
    final uri = Uri.parse('$_baseFunctionUrl/createSslCommerzSession');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderId': orderId,
        'amount': amount,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'paymentProvider': paymentProvider,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw Exception(
          'Payment API not found (404). Deploy Firebase functions: createSslCommerzSession.',
        );
      }

      final preview = response.body.length > 180
          ? '${response.body.substring(0, 180)}...'
          : response.body;
      throw Exception(
        'Payment session failed (${response.statusCode}). Response: $preview',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['gatewayUrl'] == null || data['tranId'] == null) {
      throw Exception('Invalid payment session response');
    }

    return SslCommerzSession(
      gatewayUrl: data['gatewayUrl'] as String,
      transactionId: data['tranId'] as String,
      callbackUrl:
          data['callbackUrl'] as String? ??
          '$_baseFunctionUrl/sslCommerzCallback',
    );
  }

  Future<bool> validatePayment({required String transactionId}) async {
    final uri = Uri.parse('$_baseFunctionUrl/validateSslCommerzPayment');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tranId': transactionId}),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['isValid'] == true;
  }
}
