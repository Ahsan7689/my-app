import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _bestSellingProducts = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get bestSellingProducts => _bestSellingProducts;
  bool get isLoading => _isLoading;

  ProductProvider() {
    fetchProducts();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      final snapshot = await _firestore.collection('products').get();
      _products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      // Separate featured and best-selling products
      _featuredProducts = _products.where((p) => p.isFeatured).toList();
      _bestSellingProducts = _products.where((p) => p.isBestSelling).toList();

    } catch (e, s) {
      developer.log('Error fetching products', name: 'my_app.product_provider', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting product by ID: $e');
    }
    return null;
  }

  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    List<Product> results = [];
    _setLoading(true);
    try {
      // Basic case-insensitive search
      String lowerCaseQuery = query.toLowerCase();
      results = _products
          .where((p) => p.name.toLowerCase().contains(lowerCaseQuery))
          .toList();

    } catch (e) {
      print('Error searching products: $e');
    } finally {
      _setLoading(false);
    }
    return results;
  }

  Future<List<ReviewModel>> getProductReviews(String productId) async {
    List<ReviewModel> reviews = [];
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      reviews = snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting reviews: $e');
    }
    return reviews;
  }

  Future<bool> addReview(ReviewModel review) async {
    _setLoading(true);
    try {
      // Add the review to the subcollection
      await _firestore
          .collection('products')
          .doc(review.productId)
          .collection('reviews')
          .add(review.toMap());

      // Use a transaction to update the product's average rating and review count
      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore.collection('products').doc(review.productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception("Product not found!");
        }

        // Calculate new average rating
        final reviewsSnapshot = await productRef.collection('reviews').get();
        final reviews = reviewsSnapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList();
        
        double totalRating = reviews.fold(0, (sum, item) => sum + item.rating);
        double averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
        int reviewCount = reviews.length;

        // Update the product document
        transaction.update(productRef, {
          'rating': averageRating,
          'reviewCount': reviewCount,
        });
      });

      // Refresh products to reflect rating changes
      await fetchProducts();
      return true;
    } catch (e) {
      developer.log('Error adding review', name: 'my_app.product_provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Admin functions
  Future<bool> addProduct(Product product, List<String> imagePaths) async {
    _setLoading(true);
    try {
      // In a real app, you would upload images to Firebase Storage and get URLs.
      // For this example, we'll just use the provided URLs directly.
      product.images = imagePaths; 

      await _firestore.collection('products').add(product.toMap());
      await fetchProducts(); // Refresh list
      return true;
    } catch (e) {
      developer.log('Error adding product', name: 'my_app.product_provider', error: e);
      return false;
    }
    finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(Product product, List<String> newImageUrls) async {
    _setLoading(true);
    try {
      // Again, handle image uploads properly in a real app
      product.images = newImageUrls;
      await _firestore.collection('products').doc(product.id).update(product.toMap());
      await fetchProducts();
      return true;
    } catch (e) {
      developer.log('Error updating product', name: 'my_app.product_provider', error: e);
      return false;
    }
    finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _firestore.collection('products').doc(productId).delete();
      await fetchProducts(); // Refresh list
      return true;
    } catch (e) {
      developer.log('Error deleting product', name: 'my_app.product_provider', error: e);
      return false;
    }
    finally {
      _setLoading(false);
    }
  }

    Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    List<Product> productList = [];
    try {
      final snapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: ids)
          .get();
          
      productList = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

    } catch (e, s) {
      developer.log('Error fetching products by IDs', name: 'my_app.product_provider', error: e, stackTrace: s);
    }
    return productList;
  }

}
