import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> findAdminProfile({
    required String firebaseUid,
    required String email,
  }) async {
    final directAdmin = await _firestore
        .collection('admins')
        .doc(firebaseUid)
        .get();
    if (directAdmin.exists) {
      return {'Id': directAdmin.id, ...?directAdmin.data()};
    }

    final adminByUid = await _firestore
        .collection('admins')
        .where('FirebaseUid', isEqualTo: firebaseUid)
        .limit(1)
        .get();
    if (adminByUid.docs.isNotEmpty) {
      final doc = adminByUid.docs.first;
      return {'Id': doc.id, ...doc.data()};
    }

    if (email.trim().isNotEmpty) {
      final adminByEmail = await _firestore
          .collection('admins')
          .where('Email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (adminByEmail.docs.isNotEmpty) {
        final doc = adminByEmail.docs.first;
        return {'Id': doc.id, ...doc.data()};
      }
    }

    final userDoc = await _firestore.collection('users').doc(firebaseUid).get();
    final userData = userDoc.data();
    if (userData != null &&
        (userData['UserType'] ?? '').toString().toLowerCase() == 'admin') {
      return {'Id': userDoc.id, ...userData};
    }
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllDriversStream() {
    return _firestore.collection('drivers').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllOrdersStream() {
    return _firestore.collection('Order').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingOrdersStream() {
    return _firestore
        .collection('Order')
        .where('Status', isEqualTo: 'Pending')
        .snapshots();
  }

  Future<void> updateAccountStatus({
    required String collection,
    required String id,
    required bool isActive,
  }) async {
    if (collection != 'users' && collection != 'drivers') {
      throw ArgumentError.value(collection, 'collection');
    }
    await _firestore.collection(collection).doc(id).set({
      'IsActive': isActive,
      'AccountStatus': isActive ? 'Active' : 'Suspended',
      'AccountStatusUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> updateDriverVerification(
    String driverId,
    bool isVerified,
  ) async {
    await _firestore.collection('drivers').doc(driverId).set({
      'IsVerified': isVerified,
      'VerificationUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  String accountChatId(String customerId, String driverId) {
    final safeCustomerId = customerId.trim().replaceAll('/', '_');
    final safeDriverId = driverId.trim().replaceAll('/', '_');
    return '${safeCustomerId}_$safeDriverId';
  }

  // add user details to Firestore
  Future<void> addUserDetail(
    Map<String, dynamic> userInfoMap,
    String id,
  ) async {
    try {
      await _firestore.collection('users').doc(id).set(userInfoMap);
      print('User data added successfully to Firestore');
    } catch (e) {
      print('Error adding user data: $e');
      rethrow;
    }
  }

  // get user details by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetail(
    String id,
  ) async {
    try {
      return await _firestore.collection('users').doc(id).get();
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserByFirebaseUid(
    String firebaseUid,
  ) async {
    try {
      return await _firestore
          .collection('users')
          .where('FirebaseUid', isEqualTo: firebaseUid)
          .limit(1)
          .get();
    } catch (e) {
      print('Error fetching user by FirebaseUid: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserByEmail(
    String email,
  ) async {
    try {
      return await _firestore
          .collection('users')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();
    } catch (e) {
      print('Error fetching user by email: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserDetail(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection('users').doc(id).update(updatedData);
      print('User data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  // Delete user data
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
      print('User deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  Future addUserOrder(
    Map<String, dynamic> userInfoMap,
    String id,
    String orderid,
  ) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Order")
        .doc(orderid)
        .set(userInfoMap);
  }

  Future addAdminOrder(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Order")
        .doc(id)
        .set(userInfoMap);
  }

  // Stream of all orders for a user (real-time)
  Stream<QuerySnapshot> getUserOrders(String userId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Order")
        .orderBy("CreatedAt", descending: true)
        .snapshots();
  }

  // ==================== DRIVER METHODS ====================

  // Add driver details to Firestore
  Future<void> addDriverDetail(
    Map<String, dynamic> driverInfoMap,
    String id,
  ) async {
    try {
      await _firestore.collection('drivers').doc(id).set(driverInfoMap);
      print('Driver data added successfully to Firestore');
    } catch (e) {
      print('Error adding driver data: $e');
      rethrow;
    }
  }

  // Get driver details by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getDriverDetail(
    String id,
  ) async {
    try {
      return await _firestore.collection('drivers').doc(id).get();
    } catch (e) {
      print('Error fetching driver data: $e');
      rethrow;
    }
  }

  Stream<bool> getDriverVerificationStream(String driverId) {
    return _firestore.collection('drivers').doc(driverId).snapshots().map((
      document,
    ) {
      return document.data()?['IsVerified'] == true;
    });
  }

  // Get driver by Firebase UID
  Future<QuerySnapshot<Map<String, dynamic>>> getDriverByFirebaseUid(
    String firebaseUid,
  ) async {
    try {
      return await _firestore
          .collection('drivers')
          .where('FirebaseUid', isEqualTo: firebaseUid)
          .limit(1)
          .get();
    } catch (e) {
      print('Error fetching driver by FirebaseUid: $e');
      rethrow;
    }
  }

  // Update driver info
  Future<void> updateDriverInfo(
    String driverId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update(updatedData);
      print('Driver data updated successfully');
    } catch (e) {
      print('Error updating driver data: $e');
      rethrow;
    }
  }

  // Update driver photo
  Future<void> updateDriverPhoto(String driverId, String photoUrl) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'PhotoUrl': photoUrl,
      });
      print('Driver photo updated successfully');
    } catch (e) {
      print('Error updating driver photo: $e');
      rethrow;
    }
  }

  // Get available orders (not yet assigned)
  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final query = await _firestore
          .collection('Order')
          .where('Status', isEqualTo: 'Pending')
          .orderBy('CreatedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['OrderId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching available orders: $e');
      return [];
    }
  }

  // Get driver's active orders
  Future<List<Map<String, dynamic>>> getDriverActiveOrders(
    String driverId,
  ) async {
    try {
      final query = await _firestore
          .collection('Order')
          .where('AssignedDriver', isEqualTo: driverId)
          .get();

      final orders = query.docs
          .map((doc) {
            final data = doc.data();
            data['OrderId'] = doc.id;
            return data;
          })
          .where((order) => _isDriverOrderStatus(order['Status']))
          .toList();

      orders.sort(_compareOrdersByCreatedAtDesc);
      return orders;
    } catch (e) {
      print('Error fetching driver active orders: $e');
      return [];
    }
  }

  // Accept an order
  Future<void> acceptOrder(String orderId, String driverId) async {
    try {
      final assignmentData = await _driverAssignmentData(driverId);
      final updateData = {
        'AssignedDriver': driverId,
        'AcceptedBy': driverId,
        'Status': 'Confirmed',
        'AcceptedAt': DateTime.now().toIso8601String(),
        'ConfirmedAt': DateTime.now().toIso8601String(),
        ...assignmentData,
      };
      await _updateOrderCopies(orderId, updateData);
      print('Order accepted successfully');
    } catch (e) {
      print('Error accepting order: $e');
      rethrow;
    }
  }

  // Stream of driver's active orders (real-time)
  Stream<QuerySnapshot<Map<String, dynamic>>> getDriverActiveOrdersStream(
    String driverId,
  ) {
    return _firestore
        .collection('Order')
        .where('AssignedDriver', isEqualTo: driverId)
        .snapshots();
  }

  bool _isDriverOrderStatus(dynamic status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'assigned':
      case 'accepted':
      case 'confirmed':
      case 'received':
      case 'in transit':
      case 'delivered':
        return true;
      default:
        return false;
    }
  }

  int _compareOrdersByCreatedAtDesc(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aCreated = (a['CreatedAt'] ?? '').toString();
    final bCreated = (b['CreatedAt'] ?? '').toString();
    return bCreated.compareTo(aCreated);
  }

  // Get all available drivers for order assignment
  Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    try {
      final query = await _firestore
          .collection('drivers')
          .where('IsAvailable', isEqualTo: true)
          .limit(50)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['Id'] = doc.id;
        // Set default values if location fields are missing
        data['CurrentLat'] = data['CurrentLat'] ?? 0.0;
        data['CurrentLng'] = data['CurrentLng'] ?? 0.0;
        data['Rating'] = data['Rating'] ?? 5.0;
        data['TotalDeliveries'] = data['TotalDeliveries'] ?? 0;
        data['Name'] = data['Name'] ?? 'Driver';
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching available drivers: $e');
      return [];
    }
  }

  // Assign order to a specific driver
  Future<void> assignOrderToDriver(String orderId, String driverId) async {
    try {
      final assignmentData = await _driverAssignmentData(driverId);
      final updateData = {
        'AssignedDriver': driverId,
        'Status': 'Assigned',
        'AssignedAt': DateTime.now().toIso8601String(),
        ...assignmentData,
      };
      await _updateOrderCopies(orderId, updateData);
      print('Order assigned to driver successfully');
    } catch (e) {
      print('Error assigning order to driver: $e');
      rethrow;
    }
  }

  // Add order to driver's active order list
  Future<void> addOrderToDriverActiveList(
    String driverId,
    String orderId,
  ) async {
    try {
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('ActiveOrders')
          .doc(orderId)
          .set({
            'OrderId': orderId,
            'AssignedAt': DateTime.now().toIso8601String(),
            'Status': 'Assigned',
          });
      print('Order added to driver active list');
    } catch (e) {
      print('Error adding order to driver active list: $e');
      rethrow;
    }
  }

  // Update driver location for real-time tracking
  Future<void> updateDriverLocation(
    String driverId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _firestore.collection('drivers').doc(driverId).set({
        'CurrentLat': latitude,
        'CurrentLng': longitude,
        'LastLocationUpdate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating driver location: $e');
      // Don't rethrow - location updates shouldn't crash the app
    }
  }

  // Update driver availability status
  Future<void> updateDriverAvailability(
    String driverId,
    bool isAvailable,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'IsAvailable': isAvailable,
        'AvailabilityUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (!isAvailable) {
        updateData.addAll({
          'CurrentLat': 0.0,
          'CurrentLng': 0.0,
          'LastLocationUpdate': '',
        });
      }

      await _firestore
          .collection('drivers')
          .doc(driverId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating driver availability: $e');
      // Don't rethrow - availability updates shouldn't crash the app
    }
  }

  // Stream of available drivers (real-time)
  Stream<QuerySnapshot> getAvailableDriversStream() {
    return _firestore
        .collection('drivers')
        .where('IsAvailable', isEqualTo: true)
        .snapshots();
  }

  // Stream of pending orders assigned to a driver
  Stream<QuerySnapshot> getDriverPendingOrdersStream(String driverId) {
    return _firestore
        .collection('Order')
        .where('AssignedDriver', isEqualTo: driverId)
        .where('Status', isEqualTo: 'Assigned')
        .snapshots();
  }

  // Decline order
  Future<void> declineOrder(String orderId, {String? driverId}) async {
    try {
      final updateData = <String, dynamic>{
        'AssignedDriver': FieldValue.delete(),
        'AcceptedBy': FieldValue.delete(),
        'Status': 'Pending',
        'DeclinedAt': DateTime.now().toIso8601String(),
      };

      if (driverId != null && driverId.isNotEmpty) {
        updateData['DeclinedByDriver'] = driverId;
        updateData['DeclinedDrivers'] = FieldValue.arrayUnion([driverId]);
      }

      await _updateOrderCopies(orderId, updateData);
      print('Order declined successfully');
    } catch (e) {
      print('Error declining order: $e');
      rethrow;
    }
  }

  // Accept order from driver app
  Future<void> acceptOrderFromDriver(String orderId, String driverId) async {
    try {
      final assignmentData = await _driverAssignmentData(driverId);
      final updateData = {
        'AssignedDriver': driverId,
        'Status': 'Confirmed',
        'AcceptedAt': DateTime.now().toIso8601String(),
        'ConfirmedAt': DateTime.now().toIso8601String(),
        'AcceptedBy': driverId,
        ...assignmentData,
      };
      await _updateOrderCopies(orderId, updateData);
      print('Order accepted by driver successfully');
    } catch (e) {
      print('Error accepting order: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getOrder(
    String orderId,
  ) async {
    try {
      return await _firestore.collection('Order').doc(orderId).get();
    } catch (e) {
      print('Error fetching order: $e');
      rethrow;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getOrderStream(
    String orderId,
  ) {
    return _firestore.collection('Order').doc(orderId).snapshots();
  }

  Future<void> ensureOrderChat({
    required String orderId,
    required String customerId,
    required String driverId,
    required String customerName,
    required String driverName,
  }) async {
    try {
      final chatId = accountChatId(customerId, driverId);
      final chatRef = _firestore.collection('OrderChats').doc(chatId);
      final chatDoc = await chatRef.get();
      final now = FieldValue.serverTimestamp();
      final chatData = <String, dynamic>{
        'ChatId': chatId,
        'OrderId': orderId,
        'OrderIds': FieldValue.arrayUnion([orderId]),
        'CustomerId': customerId,
        'DriverId': driverId,
        'CustomerName': customerName,
        'DriverName': driverName,
        'UpdatedAt': now,
      };

      if (!chatDoc.exists) {
        chatData.addAll({
          'CreatedAt': now,
          'LastMessage': '',
          'LastMessageAt': now,
          'LastSenderId': '',
          'LastSenderRole': '',
        });
      }

      await chatRef.set(chatData, SetOptions(merge: true));
    } catch (e) {
      print('Error ensuring order chat: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getOrderChatMessages(
    String chatId,
  ) {
    return _firestore
        .collection('OrderChats')
        .doc(chatId)
        .collection('Messages')
        .orderBy('CreatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDriverOrderChats(
    String driverId,
  ) {
    return _firestore
        .collection('OrderChats')
        .where('DriverId', isEqualTo: driverId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCustomerOrderChats(
    String customerId,
  ) {
    return _firestore
        .collection('OrderChats')
        .where('CustomerId', isEqualTo: customerId)
        .snapshots();
  }

  Future<void> sendOrderChatMessage({
    required String orderId,
    required String customerId,
    required String driverId,
    required String customerName,
    required String driverName,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
  }) async {
    try {
      final trimmedMessage = message.trim();
      if (trimmedMessage.isEmpty) return;

      final chatId = accountChatId(customerId, driverId);
      final chatRef = _firestore.collection('OrderChats').doc(chatId);
      final messageRef = chatRef.collection('Messages').doc();
      final now = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(chatRef, {
        'ChatId': chatId,
        'OrderId': orderId,
        'OrderIds': FieldValue.arrayUnion([orderId]),
        'CustomerId': customerId,
        'DriverId': driverId,
        'CustomerName': customerName,
        'DriverName': driverName,
        'LastMessage': trimmedMessage,
        'LastMessageAt': now,
        'LastSenderId': senderId,
        'LastSenderRole': senderRole,
        'UpdatedAt': now,
      }, SetOptions(merge: true));
      batch.set(messageRef, {
        'Message': trimmedMessage,
        'SenderId': senderId,
        'SenderName': senderName,
        'SenderRole': senderRole,
        'CreatedAt': now,
      });

      await batch.commit();
    } catch (e) {
      print('Error sending order chat message: $e');
      rethrow;
    }
  }

  Future<void> updateDeliveryStatus({
    required String orderId,
    required String driverId,
    required String status,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updateData = <String, dynamic>{
        'Status': status,
        'LastStatusUpdateAt': now,
        'UpdatedByDriver': driverId,
        'StatusHistory': FieldValue.arrayUnion([
          {'Status': status, 'DriverId': driverId, 'UpdatedAt': now},
        ]),
      };

      switch (status) {
        case 'Confirmed':
          updateData['ConfirmedAt'] = now;
          break;
        case 'Received':
          updateData['ReceivedAt'] = now;
          break;
        case 'In Transit':
          updateData['InTransitAt'] = now;
          break;
        case 'Delivered':
          updateData['DeliveredAt'] = now;
          break;
      }

      await _updateOrderCopies(orderId, updateData);

      if (status == 'Delivered' && driverId.isNotEmpty) {
        await _firestore.collection('drivers').doc(driverId).set({
          'TotalDeliveries': FieldValue.increment(1),
          'LastDeliveryCompletedAt': now,
        }, SetOptions(merge: true));
      }

      print('Order status updated successfully');
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _driverAssignmentData(String driverId) async {
    if (driverId.isEmpty) return {};

    try {
      final driverDoc = await _firestore
          .collection('drivers')
          .doc(driverId)
          .get();
      final data = driverDoc.data();
      if (data == null) return {};

      return {
        'DriverName': (data['Name'] ?? 'Driver').toString(),
        'DriverPhone': (data['Phone'] ?? '').toString(),
        'DriverEmail': (data['Email'] ?? '').toString(),
      };
    } catch (e) {
      print('Error fetching driver assignment data: $e');
      return {};
    }
  }

  Future<void> _updateOrderCopies(
    String orderId,
    Map<String, dynamic> updateData,
  ) async {
    final orderRef = _firestore.collection('Order').doc(orderId);
    final orderDoc = await orderRef.get();
    await orderRef.update(updateData);

    final data = orderDoc.data();
    final userId = (data?['UserId'] ?? '').toString();
    if (userId.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('Order')
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));
    }
  }

  // Update order payment status
  Future<void> updateOrderPaymentStatus({
    required String userId,
    required String orderId,
    required String paymentStatus,
    required String paymentMethod,
    required String paymentProvider,
    required double paidAmount,
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'PaymentStatus': paymentStatus,
        'PaymentMethod': paymentMethod,
        'PaymentProvider': paymentProvider,
        'PaidAmount': paidAmount.toStringAsFixed(0),
        'TransactionId': transactionId ?? '',
        'PaymentCompletedAt': DateTime.now().toIso8601String(),
      };

      // Update in main Order collection
      await _firestore.collection('Order').doc(orderId).update(updateData);

      // Update in user's orders subcollection
      if (userId.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('Order')
            .doc(orderId)
            .update(updateData);
      }

      print('Order payment status updated successfully');
    } catch (e) {
      print('Error updating order payment status: $e');
      rethrow;
    }
  }
}
