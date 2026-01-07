// ==================================================
// Program Name   : label_model.dart
// Purpose        : Data model for labels/tags used on notes/tasks
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 21 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

class Label extends BaseEntity {
  @override
  final String? id;
  @override
  final String name;
  final ComponentType? type;
  final int count;

  Label({
    required this.id,
    required this.name,
    required this.type,
    required this.count,
  });

  factory Label.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Label(
      id: documentSnapshot.id,
      name: data['name'] as String,
      type: ComponentType.convertFromString(data['type'] as String),
      count: (data['count'] as num).toInt(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type != null ? ComponentType.convertToString(type!) : null,
      'count': count,
    };
  }

  Label copyWith({String? id, String? name, ComponentType? type, int? count}) {
    return Label(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      count: count ?? this.count,
    );
  }

  @override
  String? get description => '';

  @override
  DateTime? get dateCreated => null;

  @override
  Label copyWithId(String? id) {
    return Label(id: id, name: name, type: type, count: count);
  }
}
