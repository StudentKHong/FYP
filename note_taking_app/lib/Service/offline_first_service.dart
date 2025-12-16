import 'package:cloud_firestore/cloud_firestore.dart';

extension FirestoreOfflineSafe on DocumentReference {
  Future<void> setOfflineSafe(Map<String, dynamic> data) async {
    await set(data, SetOptions(merge: true)).catchError((ex) {
      throw Exception(ex.toString());
    });
  }
}

extension CollectionOfflineSafe on CollectionReference {
  Future<DocumentReference> addOfflineSafe(Map<String, dynamic> data) async {
    final documentReference = doc();
    data['id'] = documentReference.id;
    documentReference.setOfflineSafe(data);
    return documentReference;
  }
}