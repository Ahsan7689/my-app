import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItemModel {
  /// The unique identifier of the wishlist item document.
  final String id;

  /// The ID of the product that has been added to the wishlist.
  final String productId;
  
  /// The ID of the user who owns this wishlist item.
  final String userId;

  /// The date and time when the item was added to the wishlist.
  final DateTime addedAt;

  WishlistItemModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.addedAt,
  });

  /// Creates a [WishlistItemModel] instance from a Firestore document snapshot.
  factory WishlistItemModel.fromMap(String id, Map<String, dynamic> map) {
    return WishlistItemModel(
      id: id,
      productId: map['productId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts a [WishlistItemModel] instance into a [Map] for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
