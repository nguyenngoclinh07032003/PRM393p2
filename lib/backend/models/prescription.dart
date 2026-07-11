import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String userId;
  final String doctorName;
  final String diagnosis;
  final List<String> medicineIds;
  final String imageUrl;
  final DateTime prescriptionDate;
  final DateTime expiryDate;
  final bool isVerified;

  Prescription({
    required this.id,
    required this.userId,
    required this.doctorName,
    required this.diagnosis,
    required this.medicineIds,
    required this.imageUrl,
    required this.prescriptionDate,
    required this.expiryDate,
    this.isVerified = false,
  });

  factory Prescription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prescription(
      id: doc.id,
      userId: data['userId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      medicineIds: List<String>.from(data['medicineIds'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      prescriptionDate: (data['prescriptionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'doctorName': doctorName,
      'diagnosis': diagnosis,
      'medicineIds': medicineIds,
      'imageUrl': imageUrl,
      'prescriptionDate': Timestamp.fromDate(prescriptionDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isVerified': isVerified,
    };
  }
}
