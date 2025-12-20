import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';

// abstract class NoteLike extends FilterableEntity {}

class Note implements AttachmentComponent, FilterableEntity {
  @override
  final String? id;
  @override
  final String? title;
  final String? content;
  final String? searchableContent;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isPinned;
  final DateTime? pinnedAt;

  // Only exist in notes.
  @override
  final bool? isArchived;
  @override
  final DateTime? viewedAt;
  @override
  final Label? label;

  // Only exist in shared notes.
  final String? labelName;

  Note({
    this.id,
    this.title,
    this.content,
    this.searchableContent,
    required this.createdAt,
    required this.viewedAt,
    required this.updatedAt,
    required this.isPinned,
    this.pinnedAt,
    required this.isArchived,
    this.label,
    this.labelName,
  });

  factory Note.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;

    // Externally handle optional fields.
    final Timestamp? dateViewed = data['viewedAt'] as Timestamp?;
    DateTime? viewedAt = dateViewed?.toDate();
    final String? labelId = data['labelId'] as String?;
    Label? label = (labelId != null)
        ? Label(id: data['labelId'] as String?, name: '', type: null, count: -1)
        : null;
    final String? labelName = data['labelName'] as String?;

    return Note(
      id: documentSnapshot.id,
      title: data['title'] as String?,
      content: data['content'] as String?,
      searchableContent: data['searchableContent'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewedAt: viewedAt,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPinned: data['isPinned'] as bool,
      pinnedAt: (data['pinnedAt'] as Timestamp?)?.toDate(),
      isArchived: data['isArchived'] as bool?,
      label: label,
      labelName: labelName,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'searchableContent': searchableContent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt,
    };
    // Only exists for notes.
    if (viewedAt != null) {
      map['viewedAt'] = viewedAt;
    }
    if (isArchived != null) {
      map['isArchived'] = isArchived;
    }
    if (label != null) {
      map['labelId'] = label!.id;
    }

    // Only exists for shared notes.
    if (labelName != null) {
      map['labelName'] = labelName;
    }

    return map;
  }

  // static Map<String, dynamic> toUpdateMap({
  //   required String id,
  //   String? title,
  //   String? content,
  //   String? searchableContent,
  //   DateTime? createdAt,
  //   DateTime? viewedAt,
  //   DateTime? updatedAt,
  //   bool? isPinned,
  //   bool? isArchived,
  //   Label? label,
  // }) {
  //   final map = <String, dynamic>{'id': id};

  //   if (title != null) map['title'] = title;
  //   if (content != null) map['content'] = content;
  //   if (searchableContent != null) map['searchableContent'] = searchableContent;
  //   if (createdAt != null) map['createdAt'] = createdAt;
  //   if (viewedAt != null) map['viewedAt'] = viewedAt;
  //   if (updatedAt != null) map['updatedAt'] = updatedAt;
  //   if (isPinned != null) map['isPinned'] = isPinned;
  //   if (isArchived != null) map['isArchived'] = isArchived;
  //   if (label != null) map['labelId'] = label.id;

  //   return map;
  // }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? searchableContent,
    bool? isPinned,
    bool? isArchived,
    Label? label,
    String? labelName,
    bool replaceLabel = false,
    bool isCreated = false,
    bool isUpdated = false,
    bool isViewed = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      searchableContent: searchableContent ?? this.searchableContent,
      createdAt: isCreated ? DateTime.now() : createdAt,
      viewedAt: isViewed ? DateTime.now() : viewedAt,
      updatedAt: isUpdated ? DateTime.now() : updatedAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: (isPinned ?? this.isPinned)
          ? (this.isPinned ? pinnedAt : DateTime.now())
          : null,
      isArchived: isArchived ?? this.isArchived,
      label: replaceLabel ? label : label ?? this.label,
      labelName: labelName ?? this.labelName,
    );
  }

  @override
  DateTime? get dateCreated => createdAt;

  @override
  DateTime? get dateModified => updatedAt;

  @override
  String? get description => searchableContent;

  @override
  String? get name => title;

  @override
  Note copyWithId(String id) {
    return Note(
      id: id,
      title: title,
      content: content,
      searchableContent: searchableContent,
      createdAt: createdAt,
      viewedAt: viewedAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
      pinnedAt: pinnedAt,
      isArchived: isArchived,
      label: label,
      labelName: labelName,
    );
  }
}
