import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;
  
  int get itemCount => _items.length;
  
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> loadCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      _items = snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> addItem(String userId, CartItemModel item) async {
    try {
      // Check if item already exists
      int existingIndex = _items.indexWhere((i) => i.productId == item.productId);
      
      if (existingIndex >= 0) {
        _items[existingIndex].quantity += item.quantity;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item.productId)
            .update({'quantity': _items[existingIndex].quantity});
      } else {
        _items.add(item);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item.productId)
            .set(item.toMap());
      }
      notifyListeners();
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  Future<void> removeItem(String userId, String productId) async {
    try {
      _items.removeWhere((item) => item.productId == productId);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .delete();
      notifyListeners();
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> updateQuantity(String userId, String productId, int quantity) async {
    try {
      int index = _items.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        _items[index].quantity = quantity;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(productId)
            .update({'quantity': quantity});
        notifyListeners();
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (var item in _items) {
        batch.delete(_firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item.productId));
      }
      await batch.commit();
      _items.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }
}