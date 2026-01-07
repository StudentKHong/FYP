// ==================================================
// Program Name   : class_repository.dart
// Purpose        : Repository handling class entity persistence
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 21 December 2025
// ==================================================

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Model/Models/class_member_model.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class ClassRepository extends BaseRepository<Class> {
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();
  ClassRepository()
    : super(
        collection: FirebaseFirestore.instance.collection("classes"),
        fromFirestore: (document) => Class.fromFirestore(document),
      );

  @override
  Future<Class> create(Class entity) async {
    // Generate 5-digit class code.
    const String charactersinCode = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Random random = Random();
    String code = '';
    for (int i = 0; i < 5; i++) {
      code += charactersinCode[random.nextInt(charactersinCode.length)];
    }

    final documentReference = collection.doc();

    // Transform class object into map.
    entity = entity.copyWith(id: documentReference.id, code: code);
    final data = entity.toMap();
    data.remove('id');

    // Create class.
    documentReference.setOfflineSafe(data);

    // Add user as class member.
    _addMemberToClass(documentReference.id);

    return entity;
  }

  @override
  Stream<List<Class>> watchAll() {
    final uid = _authController.user.value?.uid;
    if (uid == null) return Stream.empty();

    // Gather all relevant class ids.
    final stream = FirebaseFirestore.instance
        .collection("class_members")
        .where('userId', isEqualTo: uid)
        .snapshots();

    return stream.asyncMap((snapshot) async {
      final List<String> classIds = snapshot.docs
          .map((document) => document['classId'] as String)
          .toSet()
          .toList();

      if (classIds.isEmpty) {
        return <Class>[];
      }

      // Gather class details based on the class ids.
      final classesQuerySnapshot = await collection
          .where(FieldPath.documentId, whereIn: classIds)
          .get();
      List<Class> classes = classesQuerySnapshot.docs
          .map((document) => Class.fromFirestore(document))
          .toList();

      return classes;
    });
  }

  @override
  Stream<int> watchAllCount() {
    final uid = _authController.user.value?.uid;
    if (uid == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection("class_members")
        .where('userId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length);
  }

  Future<(Class data, bool alreadyJoined)> join(String code) async {
    // Verify the class code.
    final querySnapshot = await super.collection
        .where('code', isEqualTo: code)
        .get();
    final documentSnapshot = querySnapshot.docs.first;
    final classId = documentSnapshot.id;
    if (!documentSnapshot.exists) {
      throw Exception("Class not found.");
    }

    // Check if user is already in the class.
    final memberQuerySnapshot = await FirebaseFirestore.instance
        .collection('class_members')
        .where('classId', isEqualTo: classId)
        .where('userId', isEqualTo: _authController.user.value?.uid)
        .limit(1)
        .get();
    if (memberQuerySnapshot.docs.isNotEmpty) {
      return (Class.fromFirestore(documentSnapshot), true);
    }

    // Add user as a class member.
    await _addMemberToClass(documentSnapshot.id);

    // Increment number of total members by 1.
    final documentReference = super.collection.doc(documentSnapshot.id);
    final RoleController roleController = Get.find<RoleController>();
    if (roleController.getUserRole() == UserType.student) {
      documentReference.setOfflineSafe({
        "total": FieldValue.increment(1),
        "totalStudents": FieldValue.increment(1),
      });
    } else if (roleController.getUserRole() == UserType.teacher) {
      documentReference.setOfflineSafe({
        "total": FieldValue.increment(1),
        "totalTeachers": FieldValue.increment(1),
      });
    }
    return (Class.fromFirestore(documentSnapshot), false);
  }

  Future<void> _addMemberToClass(String classId) async {
    // Add user as member of the class.
    final classMemberCollection = FirebaseFirestore.instance.collection(
      'class_members',
    );
    if (_authController.user.value == null) {
      throw Exception("User not authenticated.");
    }
    final classMember = ClassMember(
      id: UniqueKey().toString(),
      classId: classId,
      userId: _authController.user.value!.uid,
      joinedAt: DateTime.now(),
      role: ClassMemberRole.convertUserTypeToMemberRole(
        _authController.user.value!.userType ?? UserType.student,
      ),
    );
    final classMap = classMember.toMap();
    classMap.remove('id');
    await classMemberCollection.add(classMap);
  }

  Future<void> leave(String classId) async {
    // Remove user from a class.
    final querySnapshot = await FirebaseFirestore.instance
        .collection('class_members')
        .where('userId', isEqualTo: _authController.user.value?.uid)
        .where('classId', isEqualTo: classId)
        .limit(1)
        .get();

    print('Query returned ${querySnapshot.docs.length} documents');
    final documentReference = querySnapshot.docs.first.reference;
    print('Deleting class member document: ${documentReference.path}');
    await documentReference.delete();

    // Decrement number of total members by 1.
    final memberDocumentReference = super.collection.doc(classId);
    final RoleController roleController = Get.find<RoleController>();
    if (roleController.getUserRole() == UserType.student) {
      memberDocumentReference.setOfflineSafe({
        "total": FieldValue.increment(-1),
        "totalStudents": FieldValue.increment(-1),
      });
    } else if (roleController.getUserRole() == UserType.teacher) {
      memberDocumentReference.setOfflineSafe({
        "total": FieldValue.increment(-1),
        "totalTeachers": FieldValue.increment(-1),
      });
    }
  }

  // Future<Map<String, dynamic>> fetchNotesAndTasks(String classId) async {
  //   final sharedNotesCollection = FirebaseFirestore.instance.collection(
  //     'shared_notes',
  //   );
  //   final sharedTasksCollection = FirebaseFirestore.instance.collection(
  //     'shared_tasks',
  //   );

  //   final snQuerySnapshot = await sharedNotesCollection
  //       .where('groupType', isEqualTo: 'class')
  //       .where('groupId', isEqualTo: classId)
  //       .get();
  //   final stQuerySnapshot = await sharedTasksCollection
  //       .where('groupType', isEqualTo: 'class')
  //       .where('groupId', isEqualTo: classId)
  //       .get();

  //   final List<Note> notesInClass = [];
  //   for (var document in snQuerySnapshot.docs) {
  //     final note = Note.fromFirestore(document);
  //     notesInClass.add(note);
  //   }

  //   final List<Task> tasksInClass = [];
  //   for (var document in stQuerySnapshot.docs) {
  //     final task = Task.fromFirestore(document);
  //     tasksInClass.add(task);
  //   }

  //   return {
  //     "notes": notesInClass,
  //     "tasks": tasksInClass
  //   };
  // }
}
