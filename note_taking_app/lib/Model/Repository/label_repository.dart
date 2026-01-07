// ==================================================
// Program Name   : label_repository.dart
// Purpose        : Repository for labels persistence and queries
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 24 December 2025
// ==================================================

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class LabelRepository extends UserRepository<Label> {
  final String baseUrl = "https://note-taking-app-zrdv.onrender.com";

  LabelRepository()
    : super(
        collectionBuilder: (uid) =>
            Repository.baseDocument(uid).collection('labels'),
        fromFirestore: (document) => Label.fromFirestore(document),
      );

  Future<void> pingServer() async {
    final response = await http
        .get(Uri.parse('$baseUrl/ping'))
        .timeout(Duration(minutes: 1));
    if (response.statusCode != 200) {
      throw Exception("Timeout occured. Unable to connect to backend.");
    }
  }

  @override
  Future<Label> create(Label entity) async {
    final data = entity.toMap();
    data.remove('id');

    // Create the label in the database.
    final documentReference = collection.doc();
    await collection.doc(documentReference.id).setOfflineSafe(data);
    entity = entity.copyWith(id: documentReference.id);
    return entity;
  }

  Stream<List<Label>> watchNoteLabels() {
    return collection
        .where(
          'type',
          isEqualTo: ComponentType.convertToString(ComponentType.note),
        )
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Label>> watchTaskLabels() {
    return collection
        .where(
          'type',
          isEqualTo: ComponentType.convertToString(ComponentType.task),
        )
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Future<void> incrementCount(String labelId, int increment) async {
    final trueIncrement = increment.abs();
    final documentReference = collection.doc(labelId);
    documentReference.setOfflineSafe({
      'count': FieldValue.increment(trueIncrement),
    });
  }

  Future<void> decrementCount(String labelId, int decrement) async {
    final trueDecrement = -decrement.abs();
    final documentReference = collection.doc(labelId);
    documentReference.setOfflineSafe({
      'count': FieldValue.increment(trueDecrement),
    });
  }

  @override
  Future<void> delete(List<String> componentIds) async {
    final uid = authController.user.value?.uid;
    if (uid == null) return;

    final noteCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');

    WriteBatch? batch;

    for (final id in componentIds) {
      // Delete label.
      await collection.doc(id).delete();

      // Remove all dependencies to the label.
      final querySnapshot = await noteCollection
          .where('labelId', isEqualTo: id)
          .get();

      batch ??= FirebaseFirestore.instance.batch();

      for (var document in querySnapshot.docs) {
        batch.update(document.reference, {'labelId': null});
      }
    }

    if (batch != null) {
      await batch.commit();
    }
  }

  Future<List<String>> generateLabel(String text, List<String> labels) async {
    final url = Uri.parse("$baseUrl/generate-labels");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text, "list_of_labels": labels}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return List<String>.from(responseData['labels']);
    } else {
      throw Exception(
        'Failed to generate label: ${response.statusCode}, ${response.body}',
      );
    }
  }
}
