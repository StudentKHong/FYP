// ==================================================
// Program Name   : count_repository.dart
// Purpose        : Repository exposing aggregated counts
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

// import 'package:cloud_firestore/cloud_firestore.dart';

// class CountRepository {
//   Future<int> getTaskCount(String uid, String labelId) async {
//     final notesCollection = FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('tasks');
//     final querySnapshot = await notesCollection
//         .where('label_id', isEqualTo: labelId)
//         .get();
//     return querySnapshot.size;
//   }

//   Future<int> getAllTasksCount(String uid) async{
//     final tasksCollection = FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('tasks');
//     final documentSnapshot = await tasksCollection.get();
//     return documentSnapshot.size;
//   }

//   Future<int> getAllNotificationsCount(String uid) async{
//     final notesCollection = FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('notifications');
//     final documentSnapshot = await notesCollection.get();
//     return documentSnapshot.size;
//   }

//   Future<int> getAllGroupsCount(String uid, String collectionName) async{
//     final memberCollection = FirebaseFirestore.instance.collection(
//       'class_members',
//     );
//     final querySnapshot = await memberCollection
//         .where('user_id', isEqualTo: uid)
//         .get();
//     return querySnapshot.size;
//   }
// }