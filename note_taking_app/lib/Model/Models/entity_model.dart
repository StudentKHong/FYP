// ==================================================
// Program Name   : entity_model.dart
// Purpose        : Base entity model with common fields and helpers
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

import 'package:note_taking_app/Model/Models/label_model.dart';

// Base entity that contains field 
abstract class BaseEntity {
  String? get id;

  String? get name;
  String? get description;
  DateTime? get dateCreated;

  Map<String, dynamic> toMap();
  copyWithId(String id);
}

abstract class FilterableEntity extends BaseEntity{
  Label? get label;
  DateTime? get dateModified;
}