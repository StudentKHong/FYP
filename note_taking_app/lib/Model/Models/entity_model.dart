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