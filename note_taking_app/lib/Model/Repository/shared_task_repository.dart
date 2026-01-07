// ==================================================
// Program Name   : shared_task_repository.dart
// Purpose        : Repository for shared tasks synchronization
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:note_taking_app/Model/Models/shared_task_model.dart';
// import 'package:note_taking_app/Model/Repository/crud_repository.dart';

// class SharedTaskRepository extends UserRepository<SharedTask> {
//   SharedTaskRepository({required String groupId, required String groupType})
//     : super(
//         collectionBuilder: (uid) => FirebaseFirestore.instance
//             .collection(
//               groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
//             )
//             .doc(groupId)
//             .collection('shared_tasks'),
//         fromFirestore: (document) => SharedTask.fromFirestore(document),
//       );

//   Future<List<SharedTask>> shareMultiple(List<SharedTask> sharedTasks) async {
//     final batch = FirebaseFirestore.instance.batch();
//     final List<SharedTask> createdTasks = [];
//     for (var task in sharedTasks) {
//       final taskWithId = task.copyWith(id: super.collection.doc().id);
//       final taskToCreate = taskWithId.toMap();
//       taskToCreate.remove('id');
//       batch.set(super.collection.doc(), taskToCreate);
//       createdTasks.add(taskWithId);
//     }
//     await batch.commit();
//     return createdTasks;
//   }
// }
