import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchUserOrders(String userId) async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      _orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();

    } catch (e, s) {
      developer.log('Error fetching user orders', name: 'my_app.order_provider', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> createOrder(OrderModel order) async {
    _setLoading(true);
    try {
      final docRef = await _firestore.collection('orders').add(order.toMap());
      _orders.insert(0, order.copyWith(id: docRef.id));
      return docRef.id;
    } catch (e, s) {
      developer.log('Error creating order', name: 'my_app.order_provider', error: e, stackTrace: s);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllOrders() async {
    _setLoading(true);
    try {
      final snapshot = await _firestore.collection('orders').orderBy('orderDate', descending: true).get();
      _orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e, s) {
      developer.log('Error fetching all orders', name: 'my_app.order_provider', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _setLoading(true);
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': newStatus});
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
      }
      return true;
    } catch (e, s) {
      developer.log('Error updating order status', name: 'my_app.order_provider', error: e, stackTrace: s);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      // This is a simplified analytics calculation.
      // In a real app, you might use Firebase Functions for more complex aggregations.
      final ordersSnapshot = await _firestore.collection('orders').get();
      final productsSnapshot = await _firestore.collection('products').get();

      double totalRevenue = ordersSnapshot.docs.fold(0, (sum, doc) => sum + doc.data()['totalAmount']);
      int totalOrders = ordersSnapshot.docs.length;
      int totalProducts = productsSnapshot.docs.length;

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'totalProducts': totalProducts,
      };
    } catch (e, s) {
      developer.log('Error getting dashboard analytics', name: 'my_app.order_provider', error: e, stackTrace: s);
      return {};
    }
  }
}
