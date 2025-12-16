import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Model/Repository/label_repository.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class NoteRepository extends UserRepository<Note> {
  NoteRepository()
    : super(
        collectionBuilder: (uid) =>
            Repository.baseDocument(uid).collection('notes'),
        fromFirestore: (document) => Note.fromFirestore(document),
      );

  @override
  Future<Note> create(Note entity) async {
    Map<String, dynamic> data = entity.toMap();
    data.remove('id');
    final documentReference = await collection.addOfflineSafe(data);
    final createdEntity = await documentReference.get();

    // Transform data into Note object (causing label to be overriden).
    // Restore the original label.
    Note newNote = fromFirestore(createdEntity);
    newNote = newNote.copyWith(label: entity.label);

    return newNote;
  }

  @override
  Stream<List<Note>> watchAll() {
    return collection
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          // Check and obtain current user uid.
          if (authController.user == null) {
            return <Note>[];
          }
          final uid = authController.user!.uid;

          List<Note> list = [];

          for (final document in snapshot.docs) {
            // Fetch note details, including labelId.
            Note data = fromFirestore(document);

            // Fetch label details using labelId.
            final labelId = data.label?.id;
            if (labelId != null) {
              final labelDocumentSnapshot = await Repository.baseDocument(
                uid,
              ).collection('labels').doc(labelId).get();
              final label = Label.fromFirestore(labelDocumentSnapshot);
              data = data.copyWith(label: label);
            }
            list.add(data);
          }

          return list;
        });
  }

  Stream<List<Note>> watchByGroup(String groupId, String groupType) {
    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_notes');
    return collection
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Note>> watchByLabel(String labelId) {
    return collection
        .where('labelId', isEqualTo: labelId)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          // Check and obtain current user uid.
          if (authController.user == null) {
            return <Note>[];
          }
          final uid = authController.user!.uid;

          List<Note> list = [];

          for (final document in snapshot.docs) {
            // Fetch note details, including labelId.
            Note data = fromFirestore(document);

            // Fetch label details using labelId.
            final labelId = data.label?.id;
            if (labelId != null) {
              final labelDocumentSnapshot = await Repository.baseDocument(
                uid,
              ).collection('labels').doc(labelId).get();
              final label = Label.fromFirestore(labelDocumentSnapshot);
              data = data.copyWith(label: label);
            }
            list.add(data);
          }

          return list;
        });
  }

  Stream<List<Note>> watchRecentNotes() {
    return collection
        .orderBy('viewedAt', descending: true)
        .limit(3)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Future<int> getNoteCount(String labelId) async {
    final snapshot = await collection
        .where('labelId', isEqualTo: labelId)
        .get();
    return snapshot.docs.length;
  }

  Future<List<Note>> shareMultiple(
    List<Note> notes,
    String groupId,
    String groupType,
  ) async {
    final isOnline = Get.find<ConnectivityService>().isOnline.value;

    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_notes');
    final List<Note> createdNotes = [];

    if (isOnline) {
      final batch = FirebaseFirestore.instance.batch();

      for (var note in notes) {
        final noteWithId = note.copyWith(id: collection.doc().id);
        final noteToCreate = noteWithId.toMap();
        noteToCreate.remove('id');
        batch.set(collection.doc(), noteToCreate);
        createdNotes.add(noteWithId);
      }
      await batch.commit();
    } else {
      for (var note in notes) {
        final documentReference = collection.doc();
        final noteWithId = note.copyWith(id: documentReference.id);
        final noteToCreate = noteWithId.toMap();
        noteToCreate.remove('id');
        documentReference.setOfflineSafe(noteToCreate);
        createdNotes.add(noteWithId);
      }
    }

    return createdNotes;
  }

  // @override
  // Future<Note> edit(Note entity) async {
  //   final documentReference = collection.doc(entity['id']);
  //   entity.remove('id');
  //   documentReference.setOfflineSafe(entity);
  //   final documentSnapshot = await documentReference.get();

  //   // Transform data into Note object (causing label to be overriden).
  //   // Restore the original label.
  //   Note updatedNote = fromFirestore(documentSnapshot);
  //   updatedNote = updatedNote.copyWith(label: entity['label'] as Label?);

  //   return updatedNote;
  // }

  Future<Note> editShared(Note note, String groupId, String groupType) async {
    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_notes');
    final documentReference = collection.doc(note.id);
    final dataToUpdate = note.toMap();
    dataToUpdate.remove('id');
    await documentReference.setOfflineSafe(dataToUpdate);

    return note;
  }

  Future<void> deleteShared(
    List<String> noteIds,
    String groupId,
    String groupType,
  ) async {
    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_notes');
    for (String noteId in noteIds) {
      await collection.doc(noteId).delete();
    }
  }

  /// Filter for future expansion of database.
  Stream<List<Note>> filter(
    String? labelId,
    DateTimeRange? dateCreated,
    DateTimeRange? dateModified,
  ) {
    Query query = collection;
    if (labelId != null) {
      query = query.where('labelId', isEqualTo: labelId);
    }
    if (dateCreated != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: dateCreated.start,
        isLessThanOrEqualTo: dateCreated.end,
      );
    }
    if (dateModified != null) {
      query = query.where(
        'updatedAt',
        isGreaterThanOrEqualTo: dateModified.start,
        isLessThanOrEqualTo: dateModified.end,
      );
    }
    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Future<void> setLabel(String labelId, List<String> itemIds) async {
    final ConnectivityService connectivityService =
        Get.find<ConnectivityService>();
    final isOnline = connectivityService.isOnline.value;

    // Batch update the labels of all selected notes.
    for (int i = 0; i < itemIds.length; i += 10) {
      final chunk = itemIds.sublist(
        i,
        i + 10 > itemIds.length ? itemIds.length : i + 10,
      );

      final querySnapshot = await super.collection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      if (isOnline) {
        final batch = FirebaseFirestore.instance.batch();
        for (final document in querySnapshot.docs) {
          final documentReference = super.collection.doc(document.id);
          batch.update(documentReference, {"labelId": labelId});
        }

        await batch.commit();
      } else {
        for (final document in querySnapshot.docs) {
          final documentReference = super.collection.doc(document.id);
          documentReference.setOfflineSafe({"labelId": labelId});
        }
      }
    }

    // Update the count of the label.
    final LabelRepository labelRepository = Get.find<LabelRepository>();
    labelRepository.incrementCount(labelId, itemIds.length);
  }
}
