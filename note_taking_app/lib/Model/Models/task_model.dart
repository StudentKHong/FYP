import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';

// abstract class TaskLike extends FilterableEntity {
//   Status? get status;
// }

class Task implements AttachmentComponent, FilterableEntity {
  @override
  final String? id;
  @override
  final String? title;
  @override
  final String? description;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? reminderDateTime;
  @override
  final DateTime createdAt;
  @override
  final DateTime? viewedAt;
  @override
  final DateTime updatedAt;
  final Status? status;
  @override
  final bool isPinned;
  final DateTime? pinnedAt;
  @override
  final bool? isArchived;
  @override
  final Label? label;

  // Only exist for shared task.
  final String? labelName;

  Task({
    required this.id,
    this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
    this.reminderDateTime,
    required this.createdAt,
    required this.viewedAt,
    required this.updatedAt,
    required this.status,
    required this.isPinned,
    this.pinnedAt,
    required this.isArchived,
    this.label,
    this.labelName,
  });

  factory Task.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Task(
      id: documentSnapshot.id,
      title: data['title'] as String?,
      description: data['description'] as String?,
      startDateTime: data['startDateTime'] != null
          ? (data['startDateTime'] as Timestamp).toDate()
          : null,
      endDateTime: data['endDateTime'] != null
          ? (data['endDateTime'] as Timestamp).toDate()
          : null,
      reminderDateTime: data['reminderDateTime'] != null
          ? (data['reminderDateTime'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewedAt: data['viewedAt'] != null
          ? (data['viewedAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: Status.convertFromString(data['status'] as String?),
      isPinned: data['isPinned'] as bool,
      pinnedAt: (data['pinnedAt'] as Timestamp?)?.toDate(),
      isArchived: data['isArchived'] as bool?,
      label: Label(
        id: data['labelId'] as String?,
        name: '',
        type: null,
        count: -1,
      ),
      labelName: data['labelName'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'reminderDateTime': reminderDateTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt,
      'isArchived': isArchived,
    };

    // Only exists for tasks.
    if (viewedAt != null) {
      map['viewedAt'] = viewedAt;
    }
    if (isArchived != null) {
      map['isArchived'] = isArchived;
    }
    if (label != null) {
      map['labelId'] = label!.id;
    }
    if (status != null) {
      map['status'] = Status.convertToString(status!);
    }

    // Only exists for shared tasks.
    if (label == null && labelName != null) {
      map['labelName'] = labelName;
    }
    return map;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? reminderDateTime,
    Status? status,
    bool? isPinned,
    bool? isArchived,
    Label? label,
    String? labelName,
    bool replaceLabel = false,
    bool replaceReminder = false,
    bool isCreated = false,
    bool isUpdated = false,
    bool isViewed = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      reminderDateTime: replaceReminder ? reminderDateTime : reminderDateTime ?? this.reminderDateTime,
      createdAt: isCreated ? DateTime.now() : createdAt,
      viewedAt: isViewed ? DateTime.now() : viewedAt,
      updatedAt: isUpdated ? DateTime.now() : updatedAt,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: isPinned != null ? (isPinned ? DateTime.now() : null): pinnedAt,
      isArchived: isArchived ?? this.isArchived,
      label: replaceLabel ? label: label ?? this.label,
      labelName: labelName ?? this.labelName,
    );
  }

  @override
  DateTime? get dateCreated => createdAt;

  @override
  DateTime? get dateModified => updatedAt;

  @override
  String? get name => title;

  @override
  Task copyWithId(String id) {
    return Task(
      id: id,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      reminderDateTime: reminderDateTime,
      createdAt: createdAt,
      viewedAt: viewedAt,
      updatedAt: updatedAt,
      status: status,
      isPinned: isPinned,
      pinnedAt: pinnedAt,
      isArchived: isArchived,
    );
  }
}
