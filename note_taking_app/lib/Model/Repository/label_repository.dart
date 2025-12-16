import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class LabelRepository extends UserRepository<Label> {
  LabelRepository()
    : super(
        collectionBuilder: (uid) =>
            Repository.baseDocument(uid).collection('labels'),
        fromFirestore: (document) => Label.fromFirestore(document),
      );

  @override
  Future<Label> create(Label entity) async {
    final data = entity.toMap();
    data.remove('id');

    // Create the label in the database.
    final documentReference = await collection.addOfflineSafe(data);
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

  Future<String> generateLabel(String text, List<String> labels) async {
    final url = Uri.parse("http://192.168.68.102:8000/generate-label");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text, "list_of_labels": labels}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['label'];
    } else {
      throw Exception('Failed to generate label: ${response.statusCode}, ${response.body}');
    }
  }
}
