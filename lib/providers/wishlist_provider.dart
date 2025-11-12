import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wishlist_item_model.dart';

class WishlistProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<WishlistItemModel> _items = [];

  List<WishlistItemModel> get items => _items;
  int get itemCount => _items.length;

  bool isInWishlist(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  Future<void> loadWishlist(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .orderBy('addedAt', descending: true)
          .get();

      _items = snapshot.docs
          .map((doc) => WishlistItemModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> addToWishlist(String userId, WishlistItemModel item) async {
    try {
      // Check if already exists
      if (isInWishlist(item.productId)) {
        await removeFromWishlist(userId, item.productId);
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(item.productId)
          .set(item.toMap());

      _items.add(item);
      notifyListeners();
    } catch (e) {
      print('Error adding to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();

      _items.removeWhere((item) => item.productId == productId);
      notifyListeners();
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  Future<void> clearWishlist(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (var item in _items) {
        batch.delete(_firestore
            .collection('users')
            .doc(userId)
            .collection('wishlist')
            .doc(item.productId));
      }
      await batch.commit();
      _items.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing wishlist: $e');
    }
  }
}