import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final DateTime addedAt;

  WishlistItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.addedAt,
  });

  factory WishlistItemModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      if (map['addedAt'] is Timestamp) {
        parsedDate = (map['addedAt'] as Timestamp).toDate();
      } else if (map['addedAt'] is String) {
        parsedDate = DateTime.parse(map['addedAt'] as String);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return WishlistItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      productImage: map['productImage'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      addedAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}