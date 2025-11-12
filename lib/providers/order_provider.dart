import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];

  List<OrderModel> get orders => _orders;

  // ==================== FIXED VERSION ====================
  // ✅ Updated: loadUserOrders() now loads only the logged-in user's orders
  Future<void> loadUserOrders(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId) // ✅ FIXED: Filter by userId
          .orderBy('orderDate', descending: true)
          .get();

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user orders: $e');
    }
  }

  Future<void> loadAllOrders() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading all orders: $e');
    }
  }

  Future<bool> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').add(order.toMap());
      await loadUserOrders(order.userId);
      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        if (status == 'delivered') 'deliveryDate': DateTime.now().toIso8601String(),
      });
      await loadAllOrders();
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('orders').get();
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();

      double totalIncome = 0;
      int totalOrders = snapshot.docs.length;
      int pendingOrders = 0;
      int deliveredOrders = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalIncome += data['totalAmount'] ?? 0;
        String status = data['status'] ?? '';
        if (status == 'pending') pendingOrders++;
        if (status == 'delivered') deliveredOrders++;
      }

      return {
        'totalIncome': totalIncome,
        'totalOrders': totalOrders,
        'totalUsers': userSnapshot.docs.length,
        'pendingOrders': pendingOrders,
        'deliveredOrders': deliveredOrders,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }
}