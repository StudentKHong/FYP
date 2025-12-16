import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';

class Class extends Group<Class> {
  final int? totalStudents;
  final int? totalTeachers;

  Class({
    required super.id,
    super.code,
    required super.name,
    super.description,
    super.createdBy,
    super.createdAt,
    super.total,
    this.totalStudents,
    this.totalTeachers,
  });

  @override
  DateTime? get dateCreated => createdAt;

  factory Class.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Class(
      id: documentSnapshot.id,
      code: data['code'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      total: (data['total'] as num) as int,
      totalStudents: (data['totalStudents'] as num) as int,
      totalTeachers: (data['totalTeachers'] as num) as int,
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
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
    };
  }

  @override
  Class copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? createdBy,
    int? total,
    int? totalStudents,
    int? totalTeachers,
    bool isCreated = false,
  }) {
    return Class(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: isCreated ? DateTime.now() : createdAt,
      total: total ?? this.total,
      totalStudents: totalStudents ?? this.totalStudents,
      totalTeachers: totalTeachers ?? this.totalTeachers,
    );
  }
  
  @override
  Class copyWithId(String id) {
    return Class(
      id: id,
      code: code,
      name: name,
      description: description,
      createdBy: createdBy,
      createdAt: createdAt,
      total: total,
      totalStudents: totalStudents,
      totalTeachers: totalTeachers,
    );
  }
}

// class GroupContent extends FilterableEntity {
//   // Either shared note or task can exist.
//   final SharedNote? sharedNote;
//   final SharedTask? sharedTask;
//   final MemberTaskStatus? memberTaskStatus;

//   GroupContent({
//     this.sharedNote,
//     this.sharedTask,
//     this.memberTaskStatus
//   });

//   bool get isNull => sharedNote == null && sharedTask == null;
//   bool get isSharedNoteNotNull => sharedNote != null;
//   bool get isSharedTaskNotNull => sharedTask != null;
//   bool get isTaskStatusNotNull => memberTaskStatus != null;

//   @override
//   DateTime? get dateCreated => !isNull
//       ? isSharedNoteNotNull
//             ? sharedNote!.dateCreated
//             : sharedTask!.dateCreated
//       : null;

//   @override
//   DateTime? get dateModified => !isNull
//       ? isSharedNoteNotNull
//             ? sharedNote!.updatedAt
//             : sharedTask!.updatedAt
//       : null;

//   @override
//   String? get description => !isNull
//       ? isSharedNoteNotNull
//             ? sharedNote!.description
//             : sharedTask!.description
//       : null;

//   @override
//   String? get id => !isNull
//       ? isSharedNoteNotNull
//             ? sharedNote!.id
//             : sharedTask!.id
//       : null;

//   @override
//   Label? get label => !isNull
//       ? isSharedNoteNotNull
//             ? Label(id: UniqueKey().toString(), name: sharedNote!.labelName ?? "", type: ComponentType.note, count: 0)
//             : Label(id: UniqueKey().toString(), name: sharedTask!.labelName ?? "", type: ComponentType.task, count: 0)
//       : null;

//   @override
//   String? get name => !isNull
//       ? isSharedNoteNotNull
//             ? sharedNote!.name
//             : sharedTask!.name
//       : null;

//   @override
//   Map<String, dynamic> toMap() {
//     return {
//       "sharedNote": sharedNote,
//       "sharedTask": sharedTask,
//     };
//   }

//   // Dummy factory to support GroupContent repository.
//   factory GroupContent.fromFirestore(DocumentSnapshot documentSnapshot) {
//     return GroupContent();
//   }

//   GroupContent copyWith({
//     SharedNote? sharedNote,
//     SharedTask? sharedTask
//   }) {
//     return GroupContent(
//       sharedNote: sharedNote,
//       sharedTask: sharedTask,
//     );
//   }
// }
