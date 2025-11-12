import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _productIds = [];
  bool _isLoading = false;

  List<String> get productIds => _productIds;
  bool get isLoading => _isLoading;
  int get itemCount => _productIds.length;

  WishlistProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadWishlist(user.uid);
      } else {
        _productIds = [];
        notifyListeners();
      }
    });
  }

  bool isWishlisted(String productId) {
    return _productIds.contains(productId);
  }

  Future<void> loadWishlist(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      _productIds = snapshot.docs.map((doc) => doc.id).toList();

    } catch (e) {
      print('Error loading wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("Cannot toggle wishlist, user is not logged in.");
      return;
    }
    final userId = user.uid;

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId);

    try {
      if (isWishlisted(productId)) {
        await docRef.delete();
        _productIds.remove(productId);
      } else {
        await docRef.set({
          'productId': productId,
          'addedAt': Timestamp.now(),
        });
        _productIds.add(productId);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling wishlist: $e');
    }
  }

  Future<void> clearWishlist() async {
     final user = _auth.currentUser;
    if (user == null) return;
    final userId = user.uid;

    try {
      final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      _productIds.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing wishlist: $e');
    }
  }
}
