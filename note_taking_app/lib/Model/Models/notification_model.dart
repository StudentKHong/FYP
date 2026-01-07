
// ==================================================
// Program Name   : notification_model.dart
// Purpose        : Model representing local/app notifications
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';

class AppNotification extends BaseEntity {
  @override
  final String? id;
  final String title;
  @override
  final String description;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;
  final DateTime? notifiedAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.referenceId,
    required this.referenceType,
    required this.createdAt,
    required this.notifiedAt,
    required this.isRead,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return AppNotification(
      id: documentSnapshot.id,
      title: data['title'] as String,
      description: data['description'] as String,
      referenceId: data['referenceId'] as String,
      referenceType: data['referenceType'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notifiedAt: (data['notifiedAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'createdAt': createdAt,
      'notifiedAt': notifiedAt,
      'isRead': isRead,
    };
  }

  AppNotification copyWith({
    String? title,
    String? description,
    String? referenceId,
    String? referenceType,
    bool isCreated = false,
    bool isNotified = false,
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: isCreated ? DateTime.now() : createdAt,
      notifiedAt: isNotified ? DateTime.now() : notifiedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  DateTime? get dateCreated => createdAt;

  @override
  String? get name => title;

  @override
  AppNotification copyWithId(String id) {
    return AppNotification(
      id: id,
      title: title,
      description: description,
      referenceId: referenceId,
      referenceType: referenceType,
      createdAt: createdAt,
      notifiedAt: notifiedAt,
      isRead: isRead,
    );
  }
}
