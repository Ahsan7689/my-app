import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String deliveryAddress;
  final String city;
  final String postalCode;
  final String phone;
  final String paymentMethod;
  final String status;
  final DateTime orderDate;
  final DateTime? deliveryDate;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.city,
    required this.postalCode,
    required this.phone,
    required this.paymentMethod,
    this.status = 'pending',
    required this.orderDate,
    this.deliveryDate,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic dateField) {
      try {
        if (dateField is Timestamp) {
          return dateField.toDate();
        } else if (dateField is String) {
          return DateTime.parse(dateField);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
      return DateTime.now();
    }

    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List?)
              ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      city: map['city'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      orderDate: parseDate(map['orderDate']),
      deliveryDate: map['deliveryDate'] != null ? parseDate(map['deliveryDate']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'city': city,
      'postalCode': postalCode,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
    };
  }
}