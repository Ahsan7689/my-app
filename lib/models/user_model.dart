import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.postalCode,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.parse(map['createdAt'] as String);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      postalCode: map['postalCode'] as String?,
      isAdmin: map['isAdmin'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (postalCode != null) 'postalCode': postalCode,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get hasDeliveryDetails =>
      phone != null &&
      phone!.isNotEmpty &&
      address != null &&
      address!.isNotEmpty &&
      city != null &&
      city!.isNotEmpty &&
      postalCode != null &&
      postalCode!.isNotEmpty;
}