// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:note_taking_app/Model/Models/enumeration.dart';
// import 'package:note_taking_app/Model/Models/label_model.dart';
// import 'package:note_taking_app/Model/Models/note_model.dart';

// class SharedNote extends NoteLike {
//   @override
//   final String? id;
//   final String? noteTitle;
//   final String? noteContent;
//   final String? searchableText;
//   final List<String>? sharedTo;
//   final DateTime sharedAt;
//   final DateTime updatedAt;
//   final String? labelName;
//   final bool isPinned;

//   SharedNote({
//     required this.id,
//     this.noteTitle,
//     this.noteContent,
//     this.searchableText,
//     this.sharedTo,
//     required this.sharedAt,
//     required this.updatedAt,
//     required this.labelName,
//     required this.isPinned,
//   });

//   static SharedNote convertFromNote(Note note) {
//     return SharedNote(
//       id: UniqueKey().toString(),
//       noteTitle: note.title,
//       noteContent: note.content,
//       searchableText: note.searchableContent,
//       sharedAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//       labelName: note.label?.name,
//       isPinned: false,
//     );
//   }

//   factory SharedNote.fromFirestore(DocumentSnapshot documentSnapshot) {
//     final data = documentSnapshot.data() as Map<String, dynamic>;
//     return SharedNote(
//       id: documentSnapshot.id,
//       noteTitle: data['noteTitle'] as String?,
//       noteContent: data['noteContent'] as String?,
//       searchableText: data['searchableText'] as String?,
//       sharedTo: data['sharedTo'] as List<String>?,
//       sharedAt: (data['sharedAt'] as Timestamp).toDate(),
//       updatedAt: (data['updatedAt'] as Timestamp).toDate(),
//       labelName: data['labelName'] as String?,
//       isPinned: data['isPinned'] as bool,
//     );
//   }

//   @override
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'noteTitle': noteTitle,
//       'noteContent': noteContent,
//       'searchableText': searchableText,
//       'sharedTo': sharedTo,
//       'sharedAt': sharedAt,
//       'updatedAt': updatedAt,
//       'labelName': labelName,
//       'isPinned': isPinned,
//     };
//   }

//   SharedNote copyWith({
//     String? id,
//     String? noteTitle,
//     String? noteContent,
//     String? searchableText,
//     String? labelName,
//     List<String>? sharedTo,
//     bool isShared = false,
//     bool isUpdated = true,
//     bool? isPinned,
//   }) {
//     return SharedNote(
//       id: id ?? this.id,
//       noteTitle: noteTitle ?? this.noteTitle,
//       noteContent: noteContent ?? this.noteContent,
//       searchableText: searchableText ?? this.searchableText,
//       sharedTo: sharedTo ?? this.sharedTo,
//       sharedAt: isShared ? DateTime.now() : sharedAt,
//       updatedAt: isUpdated ? DateTime.now() : updatedAt,
//       labelName: labelName ?? this.labelName,
//       isPinned: isPinned ?? this.isPinned,
//     );
//   }

//   @override
//   DateTime? get dateCreated => sharedAt;

//   @override
//   String? get description => searchableText;

//   @override
//   String? get name => noteTitle;

//   @override
//   DateTime? get dateModified => updatedAt;

//   @override
//   Label? get label => Label(
//     id: UniqueKey().toString(),
//     name: labelName ?? '',
//     type: ComponentType.note,
//     count: 0,
//   );
// }
