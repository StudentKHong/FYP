// ==================================================
// Program Name   : crud_repository.dart
// Purpose        : Generic CRUD repository base and helpers
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 19 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

// Handle repository for components such as note, task, class and team.
abstract class Repository<T extends BaseEntity> {
  static DocumentReference baseDocument(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Stream<List<T>> watchAll();
  Stream<T?> watchById(String id);
  Stream<int> watchAllCount();

  Future<void> delete(List<String> componentIds);
  Future<List<T>> edit(List<T> entities);
  // Future<T> editSpecificFields(Map<String, dynamic> fieldsToUpdate);
  Future<T> create(T entity);
  // Future<List<T>> get();
  // Future<dynamic> getById(String id);
  // Future<int?> getAllCount();
}

abstract class BaseRepository<T extends BaseEntity> implements Repository<T> {
  @protected
  CollectionReference collection;
  final T Function(DocumentSnapshot document) fromFirestore;
  BaseRepository({required this.collection, required this.fromFirestore});

  String? get orderByField => "updatedAt";

  @override
  Stream<List<T>> watchAll() {
    Query query = collection;

    if (orderByField != null) {
      query = query.orderBy(orderByField!, descending: true);
    }

    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  @override
  Stream<T?> watchById(String id) {
    return collection
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.exists ? fromFirestore(snapshot) : null);
  }

  @override
  Future<T> create(T entity) async {
    Map<String, dynamic> data = entity.toMap();
    data.remove('id');
    final documentReference = collection.doc();
    documentReference.setOfflineSafe(data);

    return entity.copyWithId(documentReference.id);
  }

  @override
  Future<void> delete(List<String> componentIds) async {
    for (final id in componentIds) {
      collection.doc(id).delete();
    }
  }

  @override
  Future<List<T>> edit(List<T> entities) async {
    final batch = FirebaseFirestore.instance.batch();

    List<T> updatedEntities = [];
    for (final entity in entities) {
      if (entity.id == null) {
        continue;
      }

      final documentReference = collection.doc(entity.id);
      final dataToUpdate = entity.toMap();
      dataToUpdate.remove('id');
      batch.update(documentReference, dataToUpdate);
      updatedEntities.add(entity);
    }
    await batch.commit();

    return updatedEntities;
  }

  @override
  Stream<int> watchAllCount() {
    return collection
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length);
  }

  // @override
  // Future<T> editSpecificFields(Map<String, dynamic> fieldsToUpdate) async {
  //   final documentReference = collection.doc(fieldsToUpdate['id']);
  //   fieldsToUpdate.remove('id');
  //   await documentReference.update(fieldsToUpdate);
  //   final documentSnapshot = await documentReference.get();
  //   final updatedNote = fromFirestore(documentSnapshot);

  //   return updatedNote;
  // }

  // @override
  // Future<List<T>> get() async {
  //   List<T> list = [];

  //   QuerySnapshot querySnapshot;
  //   if (orderByField != null) {
  //     querySnapshot = await collection
  //         .orderBy(orderByField!, descending: true)
  //         .get();
  //   } else {
  //     querySnapshot = await collection.get();
  //   }

  //   for (final document in querySnapshot.docs) {
  //     final data = fromFirestore(document);
  //     list.add(data);
  //   }

  //   return list;
  // }

  // @override
  // Future<T> getById(String id) async {
  //   final documentSnapshot = await collection.doc(id).get();
  //   return fromFirestore(documentSnapshot);
  // }
}

abstract class UserRepository<T extends BaseEntity> extends BaseRepository<T> {
  final AuthenticationController authController =
      Get.find<AuthenticationController>();
  final CollectionReference Function(String uid) _collectionBuilder;
  UserRepository({
    required CollectionReference Function(String uid) collectionBuilder,
    required super.fromFirestore,
  }) : _collectionBuilder = collectionBuilder,
       super(collection: FirebaseFirestore.instance.collection('temp'));

  @override
  CollectionReference get collection {
    final uid = authController.user.value?.uid;

    if (uid == null || uid.isEmpty) {
      throw Exception('Please login again to continue.');
    }
    return _collectionBuilder(uid);
  }
}
