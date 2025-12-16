import 'package:note_taking_app/Model/Models/entity_model.dart';

abstract class Group<T extends Group<T>> extends BaseEntity {
  @override
  final String? id;
  final String? code;
  @override
  final String name;
  @override
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final int? total;

  Group({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.total,
  });

  @override
  DateTime? get dateCreated => createdAt;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'total': total 
    };
  }

  @override
  T copyWithId(String id);

  T copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? createdBy,
    int? total,
    bool isCreated = false
  });
}
