// ==================================================
// Program Name   : offline_first_service.dart
// Purpose        : Extensions to safely write data for offline-first behaviour
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 24 December 2025
// ==================================================

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
    documentReference.setOfflineSafe(data);
    return documentReference;
  }
}