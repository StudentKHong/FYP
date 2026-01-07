// ==================================================
// Program Name   : team_model.dart
// Purpose        : Data model representing a team entity
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';

class Team extends Group<Team> {
  Team({
    required super.id,
    super.code,
    required super.name,
    super.description,
    super.createdBy,
    super.createdAt,
    super.total,
  });

  factory Team.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Team(
      id: documentSnapshot.id,
      code: data['code'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      total: (data['total'] as num) as int,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'total': total,
    };
  }

  @override
  Team copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? createdBy,
    int? total,
    bool isCreated = false,
  }) {
    return Team(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: isCreated ? DateTime.now() : createdAt,
      total: total ?? this.total,
    );
  }
  
  @override
  Team copyWithId(String id) {
    return Team(
      id: id,
      code: code,
      name: name,
      description: description,
      createdBy: createdBy,
      createdAt: createdAt,
      total: total,
    );
  }
}