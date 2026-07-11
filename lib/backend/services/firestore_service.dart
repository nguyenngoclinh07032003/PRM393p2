import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic methods for CRUD operations
  
  // Create
  Future<String> createDocument(String collection, Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  // Read single document
  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  // Read all documents in collection
  Stream<QuerySnapshot> getCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Read with query
  Stream<QuerySnapshot> getCollectionWithQuery(
    String collection, {
    String? field,
    dynamic value,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Update
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // Delete
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Batch operations
  WriteBatch batch() {
    return _firestore.batch();
  }

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to commit batch: $e');
    }
  }
}
