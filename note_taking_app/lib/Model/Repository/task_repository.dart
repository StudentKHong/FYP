import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Model/Repository/label_repository.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class TaskRepository extends UserRepository<Task> {
  final labelsMap = <String, Label>{}.obs;

  TaskRepository()
    : super(
        collectionBuilder: (uid) =>
            Repository.baseDocument(uid).collection('tasks'),
        fromFirestore: (document) => Task.fromFirestore(document),
      );

  Stream<List<Label>> watchLabels() {
    final uid = authController.user.value!.uid;
    return Repository.baseDocument(uid).collection('labels').snapshots().map((
      snapshot,
    ) {
      final labels = snapshot.docs.map(Label.fromFirestore).toList();
      labelsMap.assignAll({for (var label in labels) label.id ?? "": label});
      return labels;
    });
  }

  @override
  Stream<List<Task>> watchAll() {
    return collection
        .where('isArchived', isNotEqualTo: true)
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedAt')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          return snapshot.docs.map((document) {
            final note = fromFirestore(document);
            final labelId = note.label?.id;

            return labelId != null && labelsMap.containsKey(labelId)
                ? note.copyWith(label: labelsMap[labelId])
                : note;
          }).toList();
          // // Check and obtain current user uid.
          // if (authController.user == null) {
          //   return <Task>[];
          // }
          // final uid = authController.user.value!.uid;

          // List<Task> list = [];

          // for (final document in snapshot.docs) {
          //   // Fetch task details, including labelId.
          //   Task data = fromFirestore(document);

          //   // Fetch label details using labelId.
          //   final labelId = data.label?.id;
          //   if (labelId != null) {
          //     final labelDocumentSnapshot = await Repository.baseDocument(
          //       uid,
          //     ).collection('labels').doc(labelId).get();

          //     if (labelDocumentSnapshot.exists) {
          //       final label = Label.fromFirestore(labelDocumentSnapshot);
          //       data = data.copyWith(label: label);
          //     }
          //   }
          //   list.add(data);
          // }

          // return list;
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
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedAt')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Task>> watchByLabel(String labelId) {
    return collection
        .where('labelId', isEqualTo: labelId)
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedAt')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          // Check and obtain current user uid.
          if (authController.user.value == null) {
            return <Task>[];
          }
          final uid = authController.user.value!.uid;

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
    for (var entity in entities) {
      if (entity.id == null) {
        continue;
      }
      // Capture old document snapshot. (For updating the old label's count.)
      final oldSnapshot = await collection.doc(entity.id).get();
      final oldTask = fromFirestore(oldSnapshot);
      final oldLabelId = oldTask.label?.id;

      // Update old and current labels' counts.
      final oldExists = Get.find<LabelController>().taskLabels.any((label) => label.id == oldLabelId);
      final matchExisting = Get.find<LabelController>().taskLabels.any(
        (label) => label.id == entity.label?.id,
      );
      if (oldLabelId != entity.label?.id) {
        final LabelRepository labelRepository = Get.find<LabelRepository>();
        if (oldLabelId != null && oldExists) {
          labelRepository.decrementCount(oldLabelId, 1);
        }
        if (entity.label != null && entity.label?.id != null) {
          if (matchExisting) {
            labelRepository.incrementCount(entity.label!.id!, 1);
          } else {
            final createdLabel = await labelRepository.create(entity.label!);
            entity = entity.copyWith(label: createdLabel);
          }
        }
      }

      // Update task.
      final documentReference = collection.doc(entity.id);
      final dataToUpdate = entity.toMap();
      dataToUpdate.remove('id');
      batch.update(documentReference, dataToUpdate);

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
    final collection = FirebaseFirestore.instance
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
