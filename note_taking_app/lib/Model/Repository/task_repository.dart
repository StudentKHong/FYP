import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Model/Repository/label_repository.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class TaskRepository extends UserRepository<Task> {
  TaskRepository()
    : super(
        collectionBuilder: (uid) =>
            Repository.baseDocument(uid).collection('tasks'),
        fromFirestore: (document) => Task.fromFirestore(document),
      );

  @override
  Stream<List<Task>> watchAll() {
    return collection
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          // Check and obtain current user uid.
          if (authController.user == null) {
            return <Task>[];
          }
          final uid = authController.user!.uid;

          List<Task> list = [];

          for (final document in snapshot.docs) {
            // Fetch task details, including labelId.
            Task data = fromFirestore(document);

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

  Stream<List<Task>> watchByGroup(String groupId, String groupType) {
    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_tasks');
    return collection
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Task>> watchByLabel(String labelId) {
    return collection
        .where('labelId', isEqualTo: labelId)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          // Check and obtain current user uid.
          if (authController.user == null) {
            return <Task>[];
          }
          final uid = authController.user!.uid;

          List<Task> list = [];

          for (final document in snapshot.docs) {
            // Fetch task details, including labelId.
            Task data = fromFirestore(document);

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

  Stream<List<Task>> watchRecentTasks() {
    return collection
        .orderBy('viewedAt', descending: true)
        .limit(3)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Future<int> getTaskCount(String labelId) async {
    final snapshot = await collection
        .where('labelId', isEqualTo: labelId)
        .get();
    return snapshot.docs.length;
  }

  Future<List<Task>> shareMultiple(
    List<Task> tasks,
    String groupId,
    String groupType,
  ) async {
    final isOnline = Get.find<ConnectivityService>().isOnline.value;

    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_tasks');
    final List<Task> createdTasks = [];

    if (isOnline) {
      final batch = FirebaseFirestore.instance.batch();

      for (var task in tasks) {
        final taskWithId = task.copyWith(id: collection.doc().id);
        final taskToCreate = taskWithId.toMap();
        taskToCreate.remove('id');
        batch.set(collection.doc(), taskToCreate);
        createdTasks.add(taskWithId);
      }
      await batch.commit();
    } else {
      for (var task in tasks) {
        final documentReference = collection.doc();
        final taskWithId = task.copyWith(id: documentReference.id);
        final taskToCreate = taskWithId.toMap();
        taskToCreate.remove('id');
        documentReference.setOfflineSafe(taskToCreate);
        createdTasks.add(taskWithId);
      }
    }

    return createdTasks;
  }

  // @override
  // Future<Task> edit(Task entity) async {
  //   final dataToUpdate = entity.toMap();
  //   final documentReference = collection.doc(dataToUpdate['id']);
  //   dataToUpdate.remove('id');
  //   documentReference.setOfflineSafe(dataToUpdate);

  //   return entity;
  // }

  Future<Task> editShared(Task task, String groupId, String groupType) async {
    final collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_tasks');
    final documentReference = collection.doc(task.id);
    final dataToUpdate = task.toMap();
    dataToUpdate.remove('id');
    await documentReference.setOfflineSafe(dataToUpdate);

    return task;
  }

  Future<void> deleteShared(
    List<String> taskIds,
    String groupId,
    String groupType,
  ) async {
    super.collection = FirebaseFirestore.instance
        .collection(
          groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
        )
        .doc(groupId)
        .collection('shared_tasks');
    for (String taskId in taskIds) {
      await collection.doc(taskId).delete();
    }
  }

  /// Filter for future expansion of database.
  Stream<List<Task>> filter(
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
