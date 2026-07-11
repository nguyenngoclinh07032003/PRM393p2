import 'package:cloud_firestore/cloud_firestore.dart';

class Symptom {
  final String id;
  final String name;
  final String description;
  final List<String> relatedMedicineIds;
  final String category;

  Symptom({
    required this.id,
    required this.name,
    required this.description,
    required this.relatedMedicineIds,
    required this.category,
  });

  factory Symptom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Symptom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      relatedMedicineIds: List<String>.from(data['relatedMedicineIds'] ?? []),
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'relatedMedicineIds': relatedMedicineIds,
      'category': category,
    };
  }
}
