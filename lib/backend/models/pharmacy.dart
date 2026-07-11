import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String imageUrl;
  final double rating;
  final bool isActive;
  final DateTime createdAt;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.imageUrl,
    this.rating = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pharmacy(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'rating': rating,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
