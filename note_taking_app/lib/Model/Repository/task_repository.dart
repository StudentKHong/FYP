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
        .where('isArchived', isNotEqualTo: true)
        .orderBy('isPinned', descending: true)
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

              if (labelDocumentSnapshot.exists) {
                final label = Label.fromFirestore(labelDocumentSnapshot);
                data = data.copyWith(label: label);
              }
            }
            list.add(data);
          }

          return list;
        });
  }

  Stream<List<Task>> watchArchived() {
    return collection
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
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

  @override
  Stream<int> watchAllCount() {
    return collection
        .where('isArchived', isNotEqualTo: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length);
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

  @override
  Future<List<Task>> edit(List<Task> entities) async {
    final batch = FirebaseFirestore.instance.batch();

    List<Task> updatedEntities = [];
    for (final entity in entities) {
      if (entity.id == null) {
        continue;
      }
      // Capture old document snapshot. (For updating the old label's count.)
      final oldSnapshot = await collection.doc(entity.id).get();
      final oldTask = fromFirestore(oldSnapshot);
      final oldLabelId = oldTask.label?.id;

      // Update task.
      final documentReference = collection.doc(entity.id);
      final dataToUpdate = entity.toMap();
      dataToUpdate.remove('id');
      batch.update(documentReference, dataToUpdate);

      // Update old and current labels' counts.
      if (oldLabelId != entity.label?.id) {
        if (oldLabelId != null) {
          Get.find<LabelRepository>().decrementCount(oldLabelId, -1);
        }
        if (entity.label?.id != null) {
          Get.find<LabelRepository>().incrementCount(entity.label!.id!, 1);
        }
      }
      updatedEntities.add(entity);
    }
    await batch.commit();
    return updatedEntities;
  }

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
