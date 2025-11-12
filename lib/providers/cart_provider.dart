import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, CartItem> _items = {};
  bool _isLoading = false;
  String? _userId;

  Map<String, CartItem> get itemsMap => _items;
  List<CartItem> get items => _items.values.toList();
  bool get isLoading => _isLoading;
  int get totalItemCount {
    return _items.values.fold(0, (total, item) => total + item.quantity);
  }

  double get totalAmount {
    return _items.values.fold(0.0, (total, item) => total + item.totalPrice);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadCart(String userId) async {
    if (userId.isEmpty) return;
    _userId = userId;
    _setLoading(true);
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('cart').get();
      _items = {
        for (var doc in snapshot.docs)
          doc.id: CartItem.fromMap(doc.data(), doc.id),
      };
    } catch (e, s) {
      developer.log("Error loading cart", name: 'my_app.cart_provider', error: e, stackTrace: s);
      // Handle error appropriately
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToCart(String productId, int quantity, double price) async {
    if (_userId == null) return;
    _setLoading(true);
    try {
      final cartItemRef = _firestore.collection('users').doc(_userId).collection('cart');

      if (_items.containsKey(productId)) {
        // Update quantity if item already exists
        final existingItem = _items[productId]!;
        final newQuantity = existingItem.quantity + quantity;
        await cartItemRef.doc(productId).update({'quantity': newQuantity});
        _items[productId] = existingItem.copyWith(quantity: newQuantity);
      } else {
        // Add new item if it does not exist
        final newItem = CartItem(
          id: productId, // Use product ID as document ID for easy access
          productId: productId,
          quantity: quantity,
          price: price,
        );
        await cartItemRef.doc(productId).set(newItem.toMap());
        _items[productId] = newItem;
      }
    } catch (e, s) {
      developer.log("Error adding to cart", name: 'my_app.cart_provider', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (_userId == null) return;
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_userId).collection('cart').doc(productId).delete();
      _items.remove(productId);
    } catch (e, s) {
      developer.log("Error removing from cart", name: 'my_app.cart_provider', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateItemQuantity(String productId, int newQuantity) async {
    if (_userId == null || !_items.containsKey(productId)) return;

    if (newQuantity <= 0) {
      // If quantity is zero or less, remove the item
      await removeFromCart(productId);
    } else {
      _setLoading(true);
      try {
        final itemRef = _firestore.collection('users').doc(_userId).collection('cart').doc(productId);
        await itemRef.update({'quantity': newQuantity});
        _items[productId] = _items[productId]!.copyWith(quantity: newQuantity);
      } catch (e, s) {
        developer.log("Error updating item quantity", name: 'my_app.cart_provider', error: e, stackTrace: s);
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> clearCart() async {
    if (_userId == null) return;
    _setLoading(true);
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection('users').doc(_userId).collection('cart').get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _items.clear();
    } catch (e, s) {
      developer.log("Error clearing cart", name: 'my_app.cart_provider', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }
}
