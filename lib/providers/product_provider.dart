import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _sortBy = 'name';

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();
  String get selectedCategory => _selectedCategory;

  Future<void> loadProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      _filteredProducts = _products;
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) => product.category == category)
          .toList();
    }
    _applySorting();
    notifyListeners();
  }

  void sortProducts(String sortBy) {
    _sortBy = sortBy;
    _applySorting();
    notifyListeners();
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'price_low':
        _filteredProducts.sort((a, b) =>
            a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_high':
        _filteredProducts.sort((a, b) =>
            b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'rating':
        _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = _selectedCategory == 'All'
          ? _products
          : _products.where((p) => p.category == _selectedCategory).toList();
    } else {
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _applySorting();
    notifyListeners();
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(id).get();
      if (doc.exists) {
        return ProductModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error getting product: $e');
    }
    return null;
  }

  // Admin functions
  Future<bool> addProduct(ProductModel product, File file) async {
    try {
      await _firestore.collection('products').add(product.toMap());
      await loadProducts();
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(String id, ProductModel product, {File? imageFile}) async {
    try {
      await _firestore.collection('products').doc(id).update(product.toMap());
      await loadProducts();
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      await loadProducts();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').add(review.toMap());
      
      // Update product rating
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: review.productId)
          .get();
      
      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'];
      }
      
      double avgRating = totalRating / reviews.docs.length;
      
      await _firestore.collection('products').doc(review.productId).update({
        'rating': avgRating,
        'reviewCount': reviews.docs.length,
      });
      
      await loadProducts();
      return true;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }
}