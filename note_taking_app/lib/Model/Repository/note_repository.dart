import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
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
        .where('isArchived', isNotEqualTo: true)
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedAt')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          return snapshot.docs.map((document) {
            final note = fromFirestore(document);
            return note;
          }).toList();
        });
  }

  Stream<List<Note>> watchArchived() {
    return collection
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Note>> watchByGroup(String groupId, String groupType) {
    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_notes');
    return collection
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedAt')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Note>> watchByLabel(String labelId) {
    return collection
        .where('labelId', isEqualTo: labelId)
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedAt')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          // Check and obtain current user uid.
          if (authController.user.value == null) {
            return <Note>[];
          }
          final uid = authController.user.value!.uid;

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

  @override
  Stream<int> watchAllCount() {
    return collection
        .where('isArchived', isNotEqualTo: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length);
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

  @override
  Future<List<Note>> edit(List<Note> entities) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      List<Note> updatedEntities = [];
      for (var entity in entities) {
        if (entity.id == null) {
          continue;
        }

        // Retrieve old note.
        Note? oldNote;
        try {
          oldNote = Get.find<NoteController>().list.firstWhere(
            (note) => note.id == entity.id,
          );
        } catch (_) {}

        if (oldNote == null) {
          final document = await collection
              .doc(entity.id)
              .get(GetOptions(source: Source.cache));
          if (document.exists) {
            oldNote = fromFirestore(document);
          } else {
            continue;
          }
        }

        Note newNote = entity.copyWith();
        // Update count of old label and new label.
        // If new label does not exist, create new.
        final labelCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(authController.user.value?.uid)
            .collection('labels');

        final oldLabelId = oldNote.label?.id;
        final newLabelId = entity.label?.id;

        if (oldLabelId != newLabelId) {
          if (oldLabelId != null) {
            batch.set(labelCollection.doc(oldLabelId), {
              'count': FieldValue.increment(-1),
            }, SetOptions(merge: true));
          }
          if (newNote.label != null) {
            final LabelController labelController = Get.find<LabelController>();
            final isExisting = labelController.noteLabels.any(
              (label) => label.id == newNote.label?.id,
            );
            if (isExisting) {
              batch.set(labelCollection.doc(newLabelId), {
                'count': FieldValue.increment(1),
              }, SetOptions(merge: true));
            } else {
              final documentReference = labelCollection.doc();
              final labelMap = newNote.label!.toMap();
              labelMap.remove('id');
              batch.set(documentReference, labelMap);
              final newLabel = newNote.label!.copyWith(
                id: documentReference.id,
              );
              newNote = newNote.copyWith(label: newLabel);
            }
          }
        }

        // Update note.
        final documentReference = collection.doc(newNote.id);
        final dataToUpdate = newNote.toMap();
        dataToUpdate.remove('id');
        batch.set(documentReference, dataToUpdate, SetOptions(merge: true));

        print("New Note: ${newNote.id}");
        print("New Note: ${newNote.name}");
        print("New Note (Label): ${newNote.label?.id}");
        print("New Note (Label): ${newNote.label?.name}");
        print("New Note: ${newNote.description}");

        updatedEntities.add(newNote);
      }

      batch.commit();
      for (final note in updatedEntities) {
        print(
          'Note id=${note.id}, '
          'title=${note.title}, '
          'label=${note.label?.id}',
        );
      }

      return updatedEntities;
    } catch (ex, stackTrace) {
      print("ERROR during batch edit: $ex");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

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
