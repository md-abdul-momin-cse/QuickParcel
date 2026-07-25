import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:quick_parcel/models/order_model.dart';

class PendingOrderService {
  static const String _pendingOrderKey = 'pending_order_data';

  // Save pending order
  static Future<void> savePendingOrder(OrderData order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = jsonEncode(order.toJson());
      await prefs.setString(_pendingOrderKey, orderJson);
      print('Pending order saved');
    } catch (e) {
      print('Error saving pending order: $e');
      rethrow;
    }
  }

  // Get pending order
  static Future<OrderData?> getPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = prefs.getString(_pendingOrderKey);
      if (orderJson != null) {
        final orderMap = jsonDecode(orderJson) as Map<String, dynamic>;
        return OrderData.fromJson(orderMap);
      }
      return null;
    } catch (e) {
      print('Error getting pending order: $e');
      return null;
    }
  }

  // Clear pending order
  static Future<void> clearPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOrderKey);
      print('Pending order cleared');
    } catch (e) {
      print('Error clearing pending order: $e');
      rethrow;
    }
  }

  // Check if pending order exists
  static Future<bool> hasPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingOrderKey);
    } catch (e) {
      print('Error checking pending order: $e');
      return false;
    }
  }
}
